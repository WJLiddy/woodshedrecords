# Woodshed Records
A toy jazz music generator

# About
Jazz music is pretty easy right? The piano player just plays chords, the bass player goes up and down, and the sax player just plays random notes. Trust me, I took a music appreciation class in high school. [Since we've already produced computer-generated vaporwave](https://github.com/WJLiddy/Macintech), procedurally generated jazz is the next logical step.

# Process
My good dude Ralph Patt set up a (website with a bunch of chords for jazz standards)[http://www.ralphpatt.com/Song.html]. I harvested all of these html files using multi download tool for firefox and put them in [charts_html/](charts_html).

The HTMLs have a format that looks like this
'''
<HTML>
<HEAD>
<TITLE>One Note Samba </TITLE>
</HEAD>
<BODY bgcolor="#FFFFFF">


<H4>ONE NOTE SAMBA</H4>

<PRE>
                              
Key of Bb      4/4                                                                                                                                  


[   Dm7      |   Db7       |   Cm7        |  B7b5        |
                             
|   Dm7      |   Db7       |   Cm7        |  B7b5        |
                                
|   Fm7      |   Bb7       |   Eb         |  Ebm         | 

|   Dm7      |   Db7       |   Cm7  B7b5  |  Bb          | 
         
||  Ebm7     |   Ab7       |   Db         |  Db          | 

|   Dbm7     |   Gb7       |   Cb         |  Cm7b5  B7b5 | 	
                    
|   Dm7      |   Db7       |   Cm7        |  B7b5        |
                             
|   Dm7      |   Db7       |   Cm7        |  B7b5        |
                                
|   Fm7      |   Bb7       |   Eb         |  Ebm         |

|   Db       |   C7        |   B          |  Bb          | 

</PRE>

</BODY>
</HTML>
'''

I have a [ruby script](html_converter.rb) that reformats these HTMLs into jsons like this

'''
{"song_name":"ONE NOTE SAMBA","key":"Bb","time":"4/4","song_data":[[["Dm7"],["Db7"],["Cm7"],["B7b5"],["Dm7"],["Db7"],["Cm7"],["B7b5"],["Fm7"],["Bb7"],["Eb"],["Ebm"],["Dm7"],["Db7"],["Cm7","B7b5"],["Bb"]],[["Ebm7"],["Ab7"],["Db"],["Db"],["Dbm7"],["Gb7"],["Cb"],["Cm7b5","B7b5"],["Dm7"],["Db7"],["Cm7"],["B7b5"],["Dm7"],["Db7"],["Cm7"],["B7b5"],["Fm7"],["Bb7"],["Eb"],["Ebm"],["Db"],["C7"],["B"],["Bb"]]]}
'''

From here, we transpose all the songs to C using [song_trasponse.rb](song_trasponse.rb)
(This actually takes a pretty big shortcut. It just rejects songs that aren't in C). 

After that, [generate_song.rb](generate_song.rb) makes a big markov hash out of the transposed songs that is used generate chord progressions. (Disclaimer: most of the time it's ii V I). An A section and a B section is created, and the chord sheet is put in [generated_songs/](generated_songs/)

Here's one that it generated:

'''
{"name":"YNKVK","tempo":130,"a_section":[["C","G7+"],["C","C","C","G7"],["C7"],["C#7","D7"],["Dm7"],["G7"],["C"],["C"]],"b_section":[["Em7b5"],["A7"],["F6"],["Fm6"],["C"],["C"],["Am7"],["Dm7"],["G7"],["C"],["Dm7","G7"],["C"],["F"],["Bm7","E7"],["A"],["A"]],"structure":[["A1","B1"],["B2","B1","B"],["B1","B"],["B1","B"]]}
'''

Got some ii V I, some secondary dominant changes, and it's not just one chord to a bar. Noice. Not sure why we don't like the "A" section but whatever.

I made a (really crappy) melody, chord, and bass generator. Here's how this song looks and sounds realized:


# Other cool links
[This guy did something similar, but with neural nets and using band in a box, which is cheating, kind of? Also his progressions are a lot richer](https://keunwoochoi.wordpress.com/2016/02/19/lstm-realbook/)

[This guy does some pretty cool stuff with neural nets, but no walking bass](https://soundcloud.com/deepjazz-ai)

[This could help with melody generation](https://jazzomat.hfm-weimar.de/dbformat/dbcontent.html)
