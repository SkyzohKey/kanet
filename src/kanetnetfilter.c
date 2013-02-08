/*                                                   
	Kanet, Control access to network   
	Copyright (C) 2010 Cyrille Colin.                    
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <string.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <linux/netfilter.h>    /* for NF_ACCEPT */
#include <arpa/inet.h>
#include <libnetfilter_queue/libnetfilter_queue.h>
#include <libnetfilter_conntrack/libnetfilter_conntrack.h>


typedef u_int32_t (*conntrack_callback)(u_int32_t ip_src, u_int32_t mark, u_int32_t rec_bytes, u_int32_t send_bytes, void* app);
typedef u_int32_t (*queue_callback)(u_int32_t ipdst, u_int32_t ipsrc, int destport, void *app);

static void *conntrack_app;
static void *queue_app;
static conntrack_callback conntrack_cb;
static queue_callback queue_cb;

int conntrack_event_cb(enum nf_conntrack_msg_type type,
        struct nf_conntrack *ct,
        void *data)
{  
	u_int32_t ip_src = ntohl(nfct_get_attr_u32(ct, ATTR_ORIG_IPV4_SRC));
	u_int32_t mark = nfct_get_attr_u32(ct, ATTR_MARK);
	u_int32_t rec_bytes = nfct_get_attr_u32(ct, ATTR_REPL_COUNTER_BYTES);
	u_int32_t send_bytes = nfct_get_attr_u32(ct, ATTR_ORIG_COUNTER_BYTES);
	
	if(mark > 0 && (rec_bytes + send_bytes) > 0) {
		//fprintf(stderr, "CONNTRACK EVENT : %u,%u,%u\n",mark, rec_bytes, send_bytes);
		(*conntrack_cb)(ip_src, mark, rec_bytes, send_bytes, conntrack_app);
	}
	return NFCT_CB_CONTINUE;
}

int init_conntrack ( conntrack_callback cb, void* app)
{
  int ret;
  struct nfct_handle *h;
  struct nf_conntrack *ct;

  char buf[1024];
  
  //
  // vala callback
  //
  conntrack_cb = cb;
  conntrack_app = app;
  
  h = nfct_open(CONNTRACK,NF_NETLINK_CONNTRACK_DESTROY);
  if (!h) {
    perror("nfct_open");
    return 0;
  }

  nfct_callback_register(h,NFCT_T_ALL, conntrack_event_cb, NULL);
  
  ret = nfct_catch(h);
  nfct_close(h);
}

static int queue_event_cb(struct nfq_q_handle *qh, struct nfgenmsg *nfmsg,
        struct nfq_data *nfa, void *data)
{
 
  int id = 0;
  struct nfqnl_msg_packet_hdr *ph;

  char* payload;
  struct iphdr* ip_header;
  struct tcphdr *tcp;
  int dstport;

  nfq_get_payload(nfa,&payload);
  
  ip_header = (struct iphdr*)payload;
  tcp = (struct tcphdr *) ( (char *) ip_header + sizeof(struct iphdr) );

  dstport =  ntohs(tcp->dest);
  u_int32_t d_addr = ntohl(ip_header->daddr);
  u_int32_t s_addr = ntohl(ip_header->saddr);
  fprintf(stderr, "%d,%d,%d %d\n",  d_addr , s_addr, dstport, (int)queue_app);
  u_int32_t mark = (*queue_cb)( d_addr , s_addr, dstport, queue_app);

  ph = nfq_get_msg_packet_hdr(nfa);
  if (ph) {
  	id = ntohl(ph->packet_id);
  }
  
  return nfq_set_verdict_mark(qh, id, NF_ACCEPT, ntohl(mark), 0, NULL);
  
}


int init_queue (int queuenumber, queue_callback cb, void* app )
{
  struct nfq_handle *h;
  struct nfq_q_handle *qh;
  struct nfnl_handle *nh;
  int fd;
  int rv;
  char buf[4096] __attribute__ ((aligned));
  fprintf(stderr, "init queue \n");
  //
  //  callback
  // 
  queue_cb = cb;
  queue_app = app;
  
  //
  // init lib
  //
  h = nfq_open();
  if (!h) {
    fprintf(stderr, "error during nfq_open()\n");
    return(1);
  }
  //
  // unbind existing handler if exist
  //
  if (nfq_unbind_pf(h, AF_INET) < 0) {
    fprintf(stderr, "error during nfq_unbind_pf()\n");
    return(1);
  }

  //
  // binding to AF_INET
  //
  if (nfq_bind_pf(h, AF_INET) < 0) {
    fprintf(stderr, "error during nfq_bind_pf()\n");
    return(1);
  }
  //
  // create queue and set call back
  //
  qh = nfq_create_queue(h,  queuenumber, &queue_event_cb, NULL);
  if (!qh) {
    fprintf(stderr, "error during nfq_create_queue()\n");
    return(1);
  }
  //	
  // set to retrieve payload
  //
  if (nfq_set_mode(qh, NFQNL_COPY_PACKET, 0xffff) < 0) {
    fprintf(stderr, "can't set packet_copy mode\n");
    return(1);
  }
  fd = nfq_fd(h);
  //
  // received loop
  //
  while ((rv = recv(fd, buf, sizeof(buf), 0)) && rv >= 0) {
    nfq_handle_packet(h, buf, rv);
  }
  
  //
  // close queue
  //
  nfq_destroy_queue(qh);
  nfq_close(h);

  return(0);
}
 
