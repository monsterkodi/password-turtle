
module.exports = (grunt) ->

    grunt.initConfig
        pkg: grunt.file.readJSON 'package.json'
                            
        shell:
            options:
                execOptions: 
                    maxBuffer: Infinity
            test: 
                command: "open index.html"
            jekyll:
                command: "bundle exec jekyll build"
                
    grunt.loadNpmTasks 'grunt-shell'

    grunt.registerTask 'default',   [ 'shell:jekyll' ]
