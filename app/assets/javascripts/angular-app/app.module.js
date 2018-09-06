angular.module('codeExecApp', [
        'ngResource',
        'ngAnimate',
        'templates', // Angular rails templates module
        'ui.router',
        'ui.ace'
    ]);

angular.module('codeExecApp')
      .run(['$http', function($http){


      }]);

angular.module('codeExecApp').config(["$httpProvider", function($httpProvider){
        $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
      }]);


angular.module('codeExecApp')
      .controller('RootController',['$scope','$rootScope',function($scope,$rootScope){

      }]);
