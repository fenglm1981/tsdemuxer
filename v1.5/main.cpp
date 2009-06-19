/*

 Copyright (C) 2009 Anton Burdinuk

 clark15b@gmail.com

*/


#include "ts.h"
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <list>
#include <getopt.h>
#include <stdlib.h>

int main(int argc,char** argv)
{
    fprintf(stderr,"tsdemux 1.50 AVCHD/Blu-Ray HDMV Transport Stream demultiplexer\n\nCopyright (C) 2009 Anton Burdinuk\n\nclark15b@gmail.com\nhttp://code.google.com/p/tsdemuxer\n\n");

    if(argc<2)
    {
        fprintf(stderr,"USAGE: ./tsdemux [-u] [-p] [-d mode] [-j] [-c channel] *.ts|*.m2ts ...\n");
        fprintf(stderr,"-u demux unknown streams\n");
        fprintf(stderr,"-p parse only\n");
        fprintf(stderr,"-d dump TS structure to STDOUT (mode=1: dump M2TS timecodes, mode=2: dump PTS/DTS, mode=3: human readable output)\n");
        fprintf(stderr,"-j join elementary streams\n");
        fprintf(stderr,"-c channel number for demux\n");
        fprintf(stderr,"\ninput files can be *.m2ts, *.mts or *.ts\n");
        fprintf(stderr,"output elementary streams to *.sup, *.m2v, *.264, *.vc1, *.ac3, *.m2a and *.pcm files\n");
        fprintf(stderr,"\n");
        return 0;
    }


    bool parse_only=false;
    int dump=0;
    bool av_only=true;
    bool join=false;
    int channel=0;

    int opt;
    while((opt=getopt(argc,argv,"pd:ujc:"))>=0)
        switch(opt)
        {
        case 'p':
            parse_only=true;
            break;
        case 'd':
            dump=atoi(optarg);
            break;
        case 'u':
            av_only=false;
            break;
        case 'j':
            join=true;
            break;
        case 'c':
            channel=atoi(optarg);
            break;
        }

    std::list<std::string> playlist;             // playlist

    while(optind<argc)
    {
        playlist.push_back(argv[optind]);
        optind++;
    }

    time_t beg_time=time(0);

    if(join)
    {
        ts::demuxer demuxer;

        for(std::list<std::string>::iterator i=playlist.begin();i!=playlist.end();++i)
        {
            const std::string& s=*i;

            demuxer.av_only=av_only;

            demuxer.channel=channel;

            demuxer.demux_file(s.c_str());

            demuxer.gen_timecodes();

            demuxer.reset();
        }
        demuxer.show();
    }else
    {
        for(std::list<std::string>::iterator i=playlist.begin();i!=playlist.end();++i)
        {
            const std::string& s=*i;

            ts::demuxer demuxer;

            demuxer.parse_only=dump>0?true:parse_only;
            demuxer.dump=dump;
            demuxer.av_only=av_only;
            demuxer.channel=channel;

            demuxer.demux_file(s.c_str());

            demuxer.show();
        }
    }

    fprintf(stderr,"\ntime: %li sec\n",time(0)-beg_time);

    return 0;
}
