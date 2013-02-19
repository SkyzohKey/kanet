/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/
[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "")]

//queue
public delegate uint32 queue_callback (uint32 ipdst, uint32 irsrc, int port);
public void init_queue(int queue_num, queue_callback qc);

//conntrack
public delegate uint32 conntrack_callback (uint32 ip_src, uint32 mark, uint32 rec_bytes, uint32 send_bytes);
public void init_conntrack(conntrack_callback cc);
