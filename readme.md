XQuerrail Framework
===================

Is the XQuerrail Framework as a standalone library.

Continuous Integration  
[![Circle CI](https://circleci.com/gh/nativelogix/xquerrail2.framework/tree/master.svg?style=svg)](https://circleci.com/gh/nativelogix/xquerrail2.framework/tree/master)

MarkLogic supported versions:  
- 7.0-4.3, 7.0-5, 7.0-5.1, 7.0-5.3, 8.0-3, 8.0-3.2 (in progress)  

Install XQuerrail Framework using npm (from src/main) run:
- ```npm install https://github.com/nativelogix/xquerrail2.framework/tarball/v0.0.11 --save```
- src/main/base.xqy should look like:
```xml
<application xmlns="http://xquerrail.com/config">
  <base>/main/node_modules/xquerrail2.framework/dist</base>
  <config>/main/_config</config>
</application>
```
In development mode from root run: 
- ```npm install```

- ```gulp watch-update-xqy```
This command will watch for changes in ```src/main/**/*.xqy``` and generate the updated files in ```dist```
