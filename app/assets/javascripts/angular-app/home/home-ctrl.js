angular.module('codeExecApp').controller('HomeCtrl', ['$scope', function ($scope ) {

  $scope.langs = [{label: "C", mode: "c_cpp" },{label: "C++", mode: "c_cpp" },{label: "Java", mode: "java" }];

  $scope.selectedLang = $scope.langs[1];

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


}]);
