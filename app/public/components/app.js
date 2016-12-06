angular.module('app', [
  'ngRoute',
  'ui.bootstrap',
  'app.inbox',
  'app.send'
])
.config(['$locationProvider', '$routeProvider', function($locationProvider, $routeProvider) {
  $locationProvider.hashPrefix('!');
  $routeProvider.otherwise({redirectTo: '/inbox'});
}]);
