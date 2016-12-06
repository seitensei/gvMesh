angular.module('app.send', [
  'ngRoute',
  'ui.bootstrap'
])
.config(['$routeProvider', function($routeProvider) {
  $routeProvider
    .when('/send', {
      templateUrl: '/components/send/send.html',
      controller: 'SendController'
    });
}])
.controller('SendController', ['$scope', '$http', function($scope, $http) {
    var d = new Date();
    $scope.formData = {};
    $scope.formData.time_created = d.toLocaleString();
    $http.get('http://193.168.1.1:8080/api/v1/clients').
    then(function(response){
       $scope.clients = response.data; 
       
    });
    $scope.formSubmit = function() {
        
        $http({
          async: true,
          crossDomain: true,
          method: 'POST',
          url: 'http://193.168.1.1:8080/api/v1/send',
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          transformRequest: function(obj) {
            var str = [];
            for(var p in obj) {
              str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
            }
            return str.join("&");
          },
          data: {dest: $scope.formData.dest, message: $scope.formData.message, time_created: $scope.formData.time_created}
        }).then(function (){
        });
    }
}]);
