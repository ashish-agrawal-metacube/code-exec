angular.module('codeExecApp').controller('HomeCtrl', ['$scope','$http', function ($scope,$http) {

  $scope.langs = [
    {label: "C", compiler: "gcc", mode: "c_cpp", default_snippet: "#include <stdio.h>\n\nint main(void) {\n\t// your code goes here\n\treturn 0;\n}\n"  },
    {label: "C++",compiler: "g++", mode: "c_cpp", default_snippet: "#include <iostream>\nusing namespace std;\n\nint main() {\n\t// your code goes here\n\treturn 0;\n}" },
    {label: "Java", compiler: "java", mode: "java", default_snippet: "/* package code_exec; // don't place package name! */\n\nimport java.util.*;\nimport java.lang.*;\nimport java.io.*;\n\n/* Name of the class has to be \"Main\" only if the class is public. */\nclass CodeExec\n{\n\tpublic static void main (String[] args) throws java.lang.Exception\n\t{\n\t\t// your code goes here\n\t}\n}" },
  ] ;

  $scope.code = {};

  $scope.selectedLang = $scope.langs[1];
  $scope.code.source = $scope.selectedLang.default_snippet;


  $scope.aceOptionSource = {
          mode: "c_cpp",
          theme:'chrome',
          onLoad: function(_editor){
            $scope.aceSession = _editor.getSession();

            _editor.setOptions({ fontSize: "16px",displayIndentGuides: true});
            _editor.$blockScrolling = Infinity;

            $scope.modeChanged = function(){
              $scope.aceSession.setMode("ace/mode/"+$scope.selectedLang.mode);
              $scope.code.source = $scope.selectedLang.default_snippet;
            };

          },
          advanced: {
            enableSnippets: true,
            enableBasicAutocompletion: true,
            enableLiveAutocompletion: true
          }
    };

    $scope.aceOptionInput = {
            mode: "text",
            theme:'textmate',
            onLoad: function(_editor){
              _editor.renderer.setShowGutter(false);
              _editor.setOptions({ fontSize: "18px", displayIndentGuides: false});
            }
    };

    $scope.aceOptionOutput = {
            mode: "text",
            onLoad: function(_editor){
              _editor.setReadOnly(true);
              _editor.renderer.setShowGutter(false);
              _editor.setOptions({ fontSize: "18px", displayIndentGuides: false});
              _editor.renderer.$cursorLayer.element.style.opacity=0
            }
      };


    $scope.run = function(){
      $scope.code.output = null;
      $scope.code.result = null;
      $scope.code.execution_time = null;
      $scope.code.memory = null;

      $scope.execution_pending = true;

      $http.post("/code/run",{source: $scope.code.source, input: $scope.code.input, lang: $scope.selectedLang.compiler}).then(function(response){
        $scope.execution_pending = false;

        var data = response.data;
        if(!data.success)
        {
          if(!data.compile)
          {
            $scope.code.result = "compile_error";
            $scope.code.output = data.compile_error;
          }
          else{
            $scope.code.result = "runtime_error";
            $scope.code.output = data.runtime_error;
          }
        }
        else {
          $scope.code.result = "success";
          $scope.code.output = data.output;
          $scope.code.execution_time = data.time;
          $scope.code.memory = data.memory;
        }
      },function(badResponse){
        $scope.execution_pending = false;
        alert("Something went wrong!!");
      });

    };



}]);
