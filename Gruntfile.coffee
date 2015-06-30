
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
                    'asciiText' : ['*.styl']

        stylus:
            options:
                compress: false
            compile:
                files:
                    'style.css':  ['style.styl']

        watch:
            sources:
                files: ['./*.coffee', '*.styl', '*.html']
                tasks: ['default']

        coffee:
            options:
                bare: true
            coffee:
                expand:  true,
                flatten: true,
                cwd:     '.',
                src:     ['.pepper/coffee/*.coffee'],
                dest:    'js',
                ext:     '.js'

        clean: ['*.css']
                            
        shell:
            options:
                execOptions: 
                    maxBuffer: Infinity
            test: 
                command: "open index.html"
                
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

    grunt.registerTask 'test',      [ 'clean', 'stylus', 'salt', 'coffee', 'shell:test' ]
    grunt.registerTask 'default',   [ 'test' ]
