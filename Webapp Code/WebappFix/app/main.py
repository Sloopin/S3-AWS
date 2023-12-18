from flask import Flask, render_template, url_for, redirect, request, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin, login_user, LoginManager, login_required, logout_user, current_user
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField
from wtforms.validators import InputRequired, Length, ValidationError
from flask_bcrypt import Bcrypt
from werkzeug.utils import secure_filename
import os
from wtforms.validators import InputRequired
from wtforms import FileField, SubmitField
import boto3
from moviepy.editor import VideoFileClip, concatenate_videoclips, vfx
from moviepy.editor import *
from azure.storage.blob import BlobServiceClient

app = Flask(__name__)

#Flask / SQLalchemy variables===================================================================================================================
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'thisisasecretkey'
app.config['UPLOAD_FOLDER'] = "/app/Uploads"
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://admin:Password01@webappdb.cnomy9vganhd.eu-central-1.rds.amazonaws.com:3306/webappdb'
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)


#login manager===================================================================================================================================
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'


@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))


class User(db.Model, UserMixin):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(20), nullable=False, unique=True)
    password = db.Column(db.String(80), nullable=False)

with app.app_context():
    db.create_all()

class RegisterForm(FlaskForm):
    username = StringField(validators=[
                           InputRequired(), Length(min=4, max=20)], render_kw={"placeholder": "Username"})

    password = PasswordField(validators=[
                             InputRequired(), Length(min=8, max=20)], render_kw={"placeholder": "Password"})

    submit = SubmitField('Register')

    def validate_username(self, username):
        existing_user_username = User.query.filter_by(
            username=username.data).first()
        if existing_user_username:
            raise ValidationError(
                'That username already exists. Please choose a different one.')


class LoginForm(FlaskForm):
    username = StringField(validators=[
                           InputRequired(), Length(min=4, max=20)], render_kw={"placeholder": "Username"})

    password = PasswordField(validators=[
                             InputRequired(), Length(min=8, max=20)], render_kw={"placeholder": "Password"})

    submit = SubmitField('Login')

class UploadFileForm(FlaskForm):
    file = FileField("File", validators=[InputRequired()])
    submit = SubmitField("Upload File")

#Home of the website==============================================================================================================================
@app.route('/')
def home():
    return render_template('index.html')
#Azure variables===================================================================================================================
connect_str = 'DefaultEndpointsProtocol=https;AccountName=casestudy3;AccountKey=NwAIUI608S98KU/z7/a/fjKM+N5RTKR5nFtNn6N5zjZ5HOHGWVuGVNtj6VBrJRfM94SFq938QWxm+ASt/5YzOw==;EndpointSuffix=core.windows.net' # retrieve the connection string from the environment variable
container_name = "casestudy3" # container name in which images will be store in the storage account

blob_service_client = BlobServiceClient.from_connection_string(conn_str=connect_str) # create a blob service client to interact with the storage account
try:
    container_client = blob_service_client.get_container_client(container=container_name) # get container client to interact with the container in which images will be stored
    container_client.get_container_properties() # get properties of the container to force exception to be thrown if container does not exist
except Exception as e:
    print(e)
    print("Creating container...")
    container_client = blob_service_client.create_container(container_name) # create a container in the storage account if it does not exist

#Upload to azure=======================================================================================================================================
@app.route("/uploadblob", methods=['GET', 'POST'])
def uploadblob():
    filenames = ""

    for file in request.files.getlist("photos"):
        try:
            container_client.upload_blob(file.filename, file) # upload the file to the container using the filename as the blob name
            filenames += file.filename + "<br /> " 
            return render_template("uploadblob2.html")    
        except Exception as e:
            print(e)
            print("Ignoring duplicate filenames") # ignore duplicate filenames
            return render_template("uploadblob3.html") 
    return render_template("uploadblob.html")    



#Login page=========================================================================================================================================
@app.route('/login', methods=['GET', 'POST'])
def login():
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user:
            if bcrypt.check_password_hash(user.password, form.password.data):
                login_user(user)
                return redirect(url_for('dashboard'))
    return render_template('login.html', form=form)

#Dashboard for choosing where to upload===================================================================================================
@app.route('/dashboard', methods=['GET', 'POST'])
@login_required
def dashboard():
    return render_template('dashboard.html')

#Logging out function==========================================================================================================
@app.route('/logout', methods=['GET', 'POST'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))



#Register new account=====================================================================================================================
@ app.route('/register', methods=['GET', 'POST'])
def register():
    form = RegisterForm()

    if form.validate_on_submit():
        hashed_password = bcrypt.generate_password_hash(form.password.data)
        new_user = User(username=form.username.data, password=hashed_password)
        db.session.add(new_user)
        db.session.commit()
        return redirect(url_for('login'))

    return render_template('register.html', form=form)

#Getting aws credentials==================================================================================================================
s3 = boto3.client('s3',
                    aws_access_key_id='AKIA5COLWWM2D5L76S63',
                    aws_secret_access_key='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'
)
BUCKET_NAME='csbucket3'

#File uploading code===========================================================================================================
@app.route('/uploadAWS',methods=['post'])
def uploadAWS():
    if request.method == 'POST':
        img = request.files['file']
        if img:
                filename = secure_filename(img.filename)
                img.save(filename)
                s3.upload_file(
                    Bucket = BUCKET_NAME,
                    Filename=filename,
                    Key = filename
                )
                msg = "Upload Done ! "

    return render_template("file_upload_to_s3.html",msg = msg)

#Relocates you to the AWS cloud uploader flask link===============================================================================
@app.route('/uploadertoAWS', methods=['GET', 'POST'])
@login_required
def uploadertoAWS():
    return render_template('file_upload_to_s3.html')


#Converter code==============================================================================================================================
@app.route('/converter', methods=['GET', 'POST'])
@login_required
def converter():
    return render_template('converter.html')

#Format conversion==============================================================================================================================
@app.route('/format-conversion', methods=['GET','POST'])
def format_conversion():
    if(request.method=='POST'):
        file_names = request.files.getlist('filename[]')
        file_format = request.form.get('file-format')

        '''UPLOADING THE FILE TO A SPECIFIC LOCATION'''
        for file_name in file_names:
            file_name.save(os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(file_name.filename)))

        for file_name in file_names:
            myvideo = VideoFileClip("/app/Uploads/"+secure_filename(file_name.filename))
            name = secure_filename(file_name.filename)[:-4]+"-NewFormat"+file_format
            myvideo.write_videofile(f"/app/OutputFiles/{name}", codec= "libx264")
            return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
        '''RETURNING THE PAGE WITH URL LINK OF Converted FILES'''
        return render_template('format-conversion.html', msg="Merged Successfully", file_path="#")     
    else:
        return render_template('format-conversion.html', msg="", file_path="")

#Resizing video==============================================================================================================================
@app.route('/resize-video', methods=['GET','POST'])
def resizing_video():
    if(request.method=='POST'):
        file_names = request.files.getlist('filename[]')
        changed_width = int(request.form.get('width'))
        changed_height = int(request.form.get('height'))
        file_format = request.form.get('file-format')

        '''UPLOADING THE FILE TO A SPECIFIC LOCATION'''
        for file_name in file_names:
            file_name.save(os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(file_name.filename)))

        for file_name in file_names:
            myvideo = VideoFileClip("/app/Uploads/"+secure_filename(file_name.filename))
            resized_video = myvideo.resize(width=changed_width, height=changed_height)
            name = secure_filename(file_name.filename)[:-4]+"-Resized"+file_format
            resized_video.write_videofile(f"/app/OutputFiles/{name}", codec="libx264")
            return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
        '''RETURNING THE PAGE WITH URL LINK OF Converted FILES'''
        return render_template('resize-video.html', msg="Merged Successfully", file_path="#")     
    else:
        return render_template('resize-video.html', msg="", file_path="")

#Merge videos==============================================================================================================================
@app.route('/merge-videos', methods=['GET', 'POST'])
def merge_videos():
    if(request.method=='POST'):
        file_names = request.files.getlist('filename[]')

        '''UPLOADING THE FILE TO A SPECIFIC LOCATION'''
        for file_name in file_names:
            file_name.save(os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(file_name.filename)))

        '''MERGING THE UPLOADED FILES'''
        clips = []
        for file_name in file_names: 
            clips.append(VideoFileClip("/app/Uploads/" + secure_filename(file_name.filename)))

        # video = CompositeVideoClip([clip1,clip2])  #CompositVideoClip class provide more flexibilty 
            merged_clip = concatenate_videoclips([clip for clip in clips])      
            name = secure_filename(file_names[0].filename)[:-4]+"-MergedVideo"+".mp4"
            merged_clip.write_videofile(f"/app/OutputFiles/{name}", codec="libx264")
        '''RETURNING THE PAGE WITH URL LINK OF MERGED FILE'''
        return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
    
    else:
        return render_template('merge-videos.html', msg="", file_path="")

#Cutting videos==============================================================================================================================
@app.route('/cut-clip', methods=['GET', 'POST'])
def cut_clip():
    if(request.method=='POST'):
        # filename, time_from, time_to
        file_name = request.files.get('filename')
        time_from = request.form.get('time_from')
        time_to = request.form.get('time_to')
        
        '''UPLOADING THE FILE TO A SPECIFIC LOCATION'''
        file_name.save(os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(file_name.filename)))
        myvideo = VideoFileClip("/app/Uploads/"+secure_filename(file_name.filename))

        trimmed_video = myvideo.subclip(int(time_from), int(time_to))
        name = secure_filename(file_name.filename)[:-4]+"-TrimmedVideo"+".mp4"
        trimmed_video.write_videofile(f"/app/OutputFiles/{name}", codec="libx264")
        
        '''RETURNING THE PAGE WITH URL LINK OF MERGED FILE'''
        return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
    else:
        return render_template('cut-clip.html', msg="", file_path="")

#Mirroring videos==============================================================================================================================
@app.route('/mirror-video', methods=['GET', 'POST'])
def mirror_video():
    if(request.method=='POST'):
        file_name = request.files.get('filename')
        axis = request.form.get('axis')

        '''UPLOADING THE FILE TO A SPECIFIC LOCATION'''
        file_name.save(os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(file_name.filename)))
        myvideo = VideoFileClip("/app/Uploads/"+secure_filename(file_name.filename))
        
        name = secure_filename(file_name.filename)[:-4]+"-Mirrored"+".mp4"

        if(axis.lower()=='x'):
            mirrored_video_on_x = myvideo.fx(vfx.mirror_x)
            mirrored_video_on_x.write_videofile(f"/app/OutputFiles/{name}", codec="libx264")
            return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
        elif(axis.lower()=='y'):
            mirrored_video_on_y = myvideo.fx(vfx.mirror_y)
            mirrored_video_on_y.write_videofile(f"/app/OutputFiles/{name}", codec="libx264")
            return send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
        else:
            pass

        '''RETURNING THE PAGE WITH URL LINK OF MERGED FILE'''
        file_path = "output_files/" + name
        send_from_directory(directory="/app/OutputFiles", path=name, as_attachment=True)
        return render_template('mirror-video.html', msg="Mirroring done Successfully", file_path=file_path) 

    else:
        return render_template('mirror-video.html', msg="", file_path="")

if __name__ == "__main__":
    # Only for debugging while developing
    app.run(host="0.0.0.0", debug=True, port=80)