xquery version "1.0-ml";
(:~Responsible for refreshing the application cache for all servers including task server.
   The application cache expands all the domains includes and keeps them in a server variable
   corresponding the the configuration uri.
 :)
import module namespace config ="http://xquerrail.com/config" at "config.xqy";
declare variable $config:application as element(config:application) external;
config:refresh-app-cache($config:application)

