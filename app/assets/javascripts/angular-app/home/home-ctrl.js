angular.module('codeExecApp').controller('HomeCtrl', ['$scope','$http', function ($scope,$http) {

  $scope.langs = [{label: "C", compiler: "gcc", mode: "c_cpp" },{label: "C++",compiler: "g++", mode: "c_cpp" },{label: "Java 8", compiler: "java", mode: "java" }];

  $scope.selectedLang = $scope.langs[1];

  $scope.code = {};

  $scope.modeChanged = function(){
    $scope.aceSession.setMode("ace/mode/"+$scope.selectedLang.mode);
  };

  $scope.aceOption = {
          mode: "c_cpp",
          theme:'chrome',
          onLoad: function(_editor){
            $scope.aceSession = _editor.getSession();

            _editor.setOptions({ fontSize: "16px",displayIndentGuides: true});
            _editor.$blockScrolling = Infinity;

          }
    };


    $scope.run = function(){

      $scope.code.lang = $scope.selectedLang.compiler;
      $http.post("/code/run",$scope.code).then(function(response){

      },function(badResponse){

      });

    };



}]);
