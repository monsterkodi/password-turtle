
module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'

        salt:
            style: 
                options:
                    verbose     : false
                    textMarker  : '//!'
                    textPrefix  : '/*'
                    textFill    : '*  '
                    textPostfix : '*/'
                files:
                    'asciiText' : ['style/*.styl']

        stylus:
            options:
                compress: false
            compile:
                files:
                    'style/style.css':  ['style/style.styl']

        watch:
            sources:
                files: ['style/*.styl', '_layouts/*.html', '_includes/*.html', '*.md']
                tasks: ['build']

        clean: ['style/*.css', '_site']
                            
        shell:
            options:
                execOptions: 
                    maxBuffer: Infinity
            test: 
                command: "open index.html"
            jekyll:
                command: "bundle exec jekyll build"
                
    ###
    npm install --save-dev grunt-contrib-watch
    npm install --save-dev grunt-contrib-coffee
    npm install --save-dev grunt-contrib-stylus
    npm install --save-dev grunt-contrib-clean
    npm install --save-dev grunt-bower-concat
    npm install --save-dev grunt-pepper
    npm install --save-dev grunt-shell
    ###

    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-stylus'
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-bower-concat'
    grunt.loadNpmTasks 'grunt-pepper'
    grunt.loadNpmTasks 'grunt-shell'

    grunt.registerTask 'build',     [ 'clean', 'stylus', 'salt', 'shell:jekyll' ]
    grunt.registerTask 'default',   [ 'build' ]
