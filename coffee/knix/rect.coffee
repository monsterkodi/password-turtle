###
00000000   00000000   0000000  000000000
000   000  000       000          000   
0000000    0000000   000          000   
000   000  000       000          000   
000   000  00000000   0000000     000   
###

class Rect

    constructor: (@x,@y,@width,@height) -> 

    contains: (r) => 
        w = r.width or 0
        h = r.hight or 0
        @x <= r.x and @y <= r.y and r.x+w <= @x+@width and r.y+h <= @y+@height

module.exports = Rect