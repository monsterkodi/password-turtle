
module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        bower_concat:
            all:
                dest: 'js/lib/bower.js'
                bowerOptions:
                    relative: false
                exclude: ['octicons', 'font-awesome']

        clean: ['password-turtle.app', 'password-turtle.zip', 'style/*.css', 'js', 'pepper', '.release.*']
            
        githubAsset:
            options:
                credentials: grunt.file.readJSON('.apitoken.json') 
                repo: 'git@github.com:monsterkodi/password-turtle.git',
                file: 'password-turtle.zip'
                
        shell:
            options:
                execOptions: 
                    maxBuffer: Infinity
            kill:
                command: "killall Electron || echo 1"
            test: 
                command: "electron ."
            start: 
                command: "open password-turtle.app"
            open: 
                command: "open password-turtle.app"
            build: 
                command: "bin/build"
                
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-bower-concat'
    grunt.loadNpmTasks 'grunt-github-release-asset'
    grunt.loadNpmTasks 'grunt-shell'

    grunt.registerTask 'build',     [ 'clean', 'bower_concat', 'shell:kill',  'shell:build',   'shell:start' ]
    grunt.registerTask 'release',   [ 'clean', 'bower_concat', 'shell:build', 'shell:release', 'githubAsset' ]
    grunt.registerTask 'test',      [ 'clean', 'bower_concat', 'shell:kill',  'shell:test' ]
    grunt.registerTask 'bower',     [ 'bower_concat' ]
    grunt.registerTask 'default',   [ 'test' ]
    
