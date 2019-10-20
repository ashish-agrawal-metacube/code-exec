### What is CodeExec ?

CodeExec is a hassle free web based compile and execution tool which allows you to compile source code and execute it against input data. Set up CodeExec on your local system and you will not be dependent on online compilers (if you use online compilers for their simplicity).

Some drawbacks of using online compilers
1. Your code may not be secure (Online compilers can leak your source codes)
2. During long competitive programming contests, online compilers face heavy traffic thus respond slowly and you have to wait for your turn into the queue
3. You are allowed to make only fixed submissions in certain duration of time
4. You require an internet connection

CodeExec eliminates all drawbacks listed above once it is installed it on your local system. You get all the simplicity of online compilers offline on your local machine. It is just one time installation effort. Currently it can be installed on Linux based operating systems and supports only C, C++ and Java. You can easily add more languages. Later in this guide I will explain how you can add a new language.

### DEMO SERVER APP
  You can check a running demo app [here](http://3.82.197.177)

### Installation on Linux

1. Install **gcc** compiler (Skip this step if you already have a **gcc** compiler or you don't want to compile C/C++ code)

   **gcc 8.1.0** installation commands for ubuntu (14.04, 16.04). Following commands may take some minutes to complete so be patient.

    ```
    sudo apt-get update -y &&
    sudo apt-get upgrade -y &&
    sudo apt-get dist-upgrade -y &&
    sudo apt-get install build-essential software-properties-common -y &&
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y &&
    sudo apt-get update -y &&
    sudo apt-get install gcc-8 g++-8 -y &&
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 60 --slave /usr/bin/g++ g++ /usr/bin/g++-8 &&
    sudo update-alternatives --config gcc
    ```
2. Install **Java** compiler (JDK) (Skip this step if you already have a **java** compiler or you don't want to compile Java code)

   **OpenJDK 8** installation commands for ubuntu (14.04, 16.04, 18.04)

   ```
   sudo apt-get update
   sudo apt install openjdk-8-jdk
   ```
3. Install **Ruby 2.6** (Ruby 2.6 is required to run the application)

	**Ruby 2.6** installation commands for ubuntu via **rvm** (Ruby Version Manager)

	  ```
    sudo apt-get install curl
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
    curl -sSL https://get.rvm.io | bash -s stable
    rvm requirements
    rvm install 2.6.0
    ```
 4. Install **nodejs** (nodejs is required for Javascript Runtime)

	  Node.js 8.x installation commands for ubuntu
    ```
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    sudo apt-get install -y nodejs
    ```
 5. Install **bundler** (Required to install gem dependencies for this application)

   	```
   	gem install bundler
   	```
 6. Install **git** and clone github repository

    ```
    sudo apt-get install git
    git clone https://github.com/ashish-agrawal-metacube/code-exec.git
    cd code-exec
    ```
  7. Install application dependencies

     Note: You should be inside **code-exec** directory to run commands given below
     ```
     bundle install
     bundle exec figaro install
     ```
  8. Set some local environment variables for application configuration

      add following properties in config/application.yml file (placed inside application directory code-exec ).
      ```
      EXECUTION_TIMEOUT: 5 # (TIME LIMIT in seconds) Time after which execution of a code should be terminated
      MAX_STDOUT: 2097152 # Max STDOUT size (in bytes)
      RAILS_MASTER_KEY: "5d13a50e85219ac60904bc8f877ffb2b" # It could be any random string
      ```
  9. Run local server

      Note: You should be inside **code-exec** directory to run commands given below
      ```
      sh run_server.sh
      ```
     Now the application should be listening on localhost at port 3001. Use **Ctrl-C** to stop the server
  10. Open application in your favourite web browser

      ```
      http://localhost:3001
      ```

## How to add a new language ?

If you want to compile a new language, First you need to download compiler of that language on your local system then you have to create an ruby class that should extends either **MLCodeExecutor** or **VMCodeExecutor**. If you are adding a language that generates a code that could be executed by Linux OS (like: C++, Bash, Objective-C) you should extend **MLCodeExecutor**. If you are adding a language that generates a code that could be executed by Virtual Machine (like: Java, Python3, Ruby) you should extend **VMCodeExecutor** and place it inside **lib/exec** folder of application. Add a check for the new language in [**lib/exec/code_executor_factory.rb**](https://github.com/ashish-agrawal-metacube/code-exec/blob/master/lib/exec/code_executor_factory.rb) and add a JSON object of your new language in **$scope.langs** at [**app/assets/javascripts/angular-app/home/home-ctrl.js**](https://github.com/ashish-agrawal-metacube/code-exec/blob/master/app/assets/javascripts/angular-app/home/home-ctrl.js). Now You have to restart the server to see the effect. You should take reference of [**lib/exec/c_executor.rb**](https://github.com/ashish-agrawal-metacube/code-exec/blob/master/lib/exec/c_executor.rb)

 ### Full example (adding Python3)

  1. Create a new file named **python3_executor.rb** inside **code-exec/lib/exec**.
     ```ruby
     require 'tmpdir'
     require "exceptions"
     require "v_m_code_executor"

     class Python3Executor < VMCodeExecutor

       def execute
         # creates an empty temp directory
         dir = Dir.mktmpdir
         begin
           # save source code to a file inside temp directory
           save_source_file("#{dir}/prog.py")

           # Python3 doesn't require compilation

           # pass command to run python3 file prog.py
           run("python3 #{dir}/prog.py")
           if @run_error.present?
             # run python3 file prog.py
             @run_error.gsub!("#{dir}/","")
             raise RunTimeError, @run_error
           else
             # calculates cpu time and memory usage (Max) of this execution
             time_and_memory("python3 #{dir}/prog.py")
           end

         ensure
           # remove temp directory.
           FileUtils.remove_entry dir
         end
       end
     end
     ```

  2. Update case statement in **lib/exec/code_executor_factory.rb** to add a check for python3
      ```ruby
      require "exceptions"
      class CodeExecutorFactory

        def self.for(lang,source,input)
          case lang
          when "gcc"
            CExecutor.new(source,input)
          when "g++"
            CppExecutor.new(source,input)
          when "java"
            JavaExecutor.new(source,input)
          when "python3" # new language
            Python3Executor.new(source,input) # create object of new language
          else
            raise LangNotSupportedError, "Language not supported: #{lang}"
          end
        end

      end
      ```
  3. Update **$scope.langs** inside **app/assets/javascripts/angular-app/home/home-ctrl.js** to add a JSON object for python3
      ```javascript
      $scope.langs = [
        {label: "C", compiler: "gcc", mode: "c_cpp", default_snippet: "#include <stdio.h>\n\nint main(void) {\n\t// your code goes here\n\treturn 0;\n}\n"  },
        {label: "C++",compiler: "g++", mode: "c_cpp", default_snippet: "#include <iostream>\nusing namespace std;\n\nint main() {\n\t// your code goes here\n\treturn 0;\n}" },
        {label: "Java", compiler: "java", mode: "java", default_snippet: "/* package code_exec; // don't place package name! */\n\nimport java.util.*;\nimport java.lang.*;\nimport java.io.*;\n\n/* Name of the class has to be \"Main\" only if the class is public. */\nclass CodeExec\n{\n\tpublic static void main (String[] args) throws java.lang.Exception\n\t{\n\t\t// your code goes here\n\t}\n}" },
        {label: "Python3", compiler: "python3", mode: "python", default_snippet: "# your code goes here" } // new language
      ] ;
      ```
       Here the value of **compiler** should match the name of condition you added in **lib/exec/code_executor_factory.rb** (in this case python3). mode is the value of Ace Editer mode that highligts the code syntax. refer [https://ace.c9.io/](https://ace.c9.io/) to get more info on Ace Editor
  4. Restart server and refresh the page
      ```
      Ctrl-C
      sh run_server.sh
      ```

### How can I help?
If you have a problem or any questions/suggestions, Please, just throw me an email at <ashish580839@gmail.com>
