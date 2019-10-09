require 'sinatra'
require 'sinatra/reloader'
require 'fileutils'
require 'sinatra/cookies' 
require 'pg'

set :public_folder, 'public'
enable :sessions

def db
    host = 'localhost'
    user = 'tokuharakenta' #自分のユーザー名を入れる
    password = ''
    dbname = 'mission'
    
# PostgreSQL クライアントのインスタンスを生成
PG::connect(
    :host => host,
    :user => user,
    :password => password,
    :dbname => dbname)
end

confirmFlag = false

#check_loginが書かれているところは全てif分の処理がされる！
def check_login
    redirect '/login' unless session[:user_id]
end

get '/' do
    if session[:user_id].nil? == true #セッションが空なら/loginページのまま
        erb :login
    else #空じゃなかったらindexを読み込む
        redirect '/index'
    end
end

post "/" do
    check_login
    erb :login 
end

#/loginにアクセスすると、ログイン（ログイン）画面が表示される。
get "/login" do
    session[:user_id] = nil
    erb :login
end

post "/login" do
    name = params[:name]
    password = params[:password]
    id = db.exec_params("SELECT id FROM users WHERE name =$1 AND password = $2",[name,password]).first
        if id
            session[:user_id] = id['id']
            redirect '/index'
        else
            redirect '/yet_login'
        end
end


#/newにアクセスすると、（新規登録）画面が表示される。
get "/new" do
    if confirmFlag
        @name = session[:name]
        @email = session[:email]
        @password = session[:password]
        confirmFlag = false
    else
        @name = ""
        @password = ""
        @email = ""
    end
    erb :new
end

#/newで記入した内容を/new_outputで確認する
post "/new" do
    @name = params[:name]
    @email = params[:email]
    @password = params[:password]

    session[:name] = params[:name]
    session[:email] = params[:email]
    session[:password] = params[:password]

    confirmFlag = true

    File.open("form.txt", mode = "a"){|f|
    f.write("#{@name},#{@email},#{@password},\n")
  }
   erb :new_output

end

get "/new_output" do
    erb :new_output
end

#/newで記入した内容でよければusersテーブルに保存され同時に/loginにいく
post "/new_output" do
        confirmFlag = false
        name = params[:name]
        email = params[:email]
        password = params[:password]
        res = db.exec_params("select * from users where name = $1 and email = $2",[name,email]).first
        unless res then
            db.exec_params("INSERT INTO users(name,email,password) VALUES($1,$2,$3)",[name,email,password])
            redirect '/login'
          else
            redirect '/already_new_output'
        end        
end

get "/index" do
    check_login
    erb :index
end

get '/form' do
    check_login
    if confirmFlag
        @name = session[:name]
        @content = session[:content]
        @taiken = session[:taiken]
        confirmFlag = false
    else
        @name = ""
        @content = ""
        @taiken = ""
    end
    erb :form
end

post '/form' do
    @name = params[:name]
    @content = params[:content]
    @taiken = params[:taiken]

    session[:name] = params[:name]
    session[:content] = params[:content]
    session[:taiken] = params[:taiken]

    confirmFlag = true

    File.open("form.txt", mode = "a"){|f|
    f.write("#{@name},#{@content},#{@taiken},\n")
  }
   erb :form_output
end

get '/form_outout' do
    erb :form_output
end

post '/form_output' do
    confirmFlag = false
    name = params[:name]
    content = params[:content]
    taiken = params[:taiken]
    db.exec_params("INSERT INTO toukou(name,content,taiken) VALUES($1,$2,$3)",[name,content,taiken])
    redirect '/news'
end

get '/news' do
    check_login
    @toukous = db.exec_params('select * from toukou')
    erb :news
end

post '/news' do
    check_login

end

get '/already_new_output' do
    erb :already_new_output
  end

  get '/yet_login' do
    erb :yet_login
  end

  