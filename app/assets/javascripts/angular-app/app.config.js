angular.module('codeExecApp').config(['$stateProvider','$urlRouterProvider', function($stateProvider,$urlRouterProvider) {

  $urlRouterProvider.otherwise('/');

  var containerState = {
    name: 'container',
    abstract: true,
    templateUrl: "angular-app/layout/application.html"
  }

  var containerPublicState = {
    name: 'container.public',
    abstract: true,
    template: '<ui-view />'
  }

  var containerPublicHome = {
    name: 'container.public.home',
    url: '/',
    controller: "HomeCtrl",
    templateUrl: "angular-app/home/home.html"
  }

  $stateProvider.state(containerState);
  $stateProvider.state(containerPublicState);
  $stateProvider.state(containerPublicHome);

}]);
