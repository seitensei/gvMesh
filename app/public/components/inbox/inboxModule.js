angular.module('app.inbox', [
  'ngRoute',
  'ui.bootstrap'
])
.config(['$routeProvider', function($routeProvider) {
  $routeProvider
    .when('/inbox', {
      templateUrl: '/components/inbox/inbox.html',
      controller: 'InboxController'
    });
}])
.controller('InboxController', ['$scope', '$http', function($scope, $http) {
    $http.get('http://193.168.1.1:8080/api/v1/inbox_list').
    then(function(response){
       $scope.inbox = response.data; 
    });
    $scope.delete = function(del_id) {
      console.log("delete:" + del_id);
        $http({
          async: true,
          crossDomain: true,
          method: 'POST',
          url: 'http://193.168.1.1:8080/api/v1/delete',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          transformRequest: function(obj) {
            var str = [];
            for(var p in obj) {
              str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
            }
            return str.join("&");
          },
          data: {id: del_id}
        }).then(function (){
          $http.get('http://193.168.1.1:8080/api/v1/inbox_list').
          then(function(response){
            $scope.inbox = response.data; 
          });
        });

    };
    $scope.refresh_inbox = function() {
      $http.get('http://193.168.1.1:8080/api/v1/inbox_list').
          then(function(response){
            $scope.inbox = response.data; 
          });
    };
    $scope.refresh_outbox = function() {
      $http({
        async: true,
        crossDomain: true,
        method: 'POST',
        url: 'http://193.168.1.1:8080/api/v1/outbox_refresh',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          transformRequest: function(obj) {
            var str = [];
            for(var p in obj) {
              str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
            }
            return str.join("&");
          },
        data: {dummy: 'dummy'}
      });
    };
}]);
