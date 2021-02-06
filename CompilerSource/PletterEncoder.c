/*
  Pletter v0.5c1

  XL2S Entertainment

  C version by jltursan 2020

*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned maxlen[7]={ 128,128+128,512+128,1024+128,2048+128,4096+128,8192+128 };
unsigned varcost[65536];

typedef struct metadata_t {
  unsigned reeks;
  unsigned cpos[7],clen[7];
} Metadata;
Metadata *m;

typedef struct pakdata_t {
  unsigned cost,mode,mlen;
} Pakdata;
Pakdata *p[7];

// char sourcefilename[128];
// char destfilename[128];


typedef struct DataHandler DataHandler;
struct DataHandler
{
    unsigned char *buf;
    int ep;
    int dp;
    int p;
    int e;
    void (*init)(DataHandler *, unsigned int);
    void (*add0)(DataHandler *);
    void (*add1)(DataHandler *);
    void (*addbit)(DataHandler *, int);
    void (*add3)(DataHandler *, int);
    void (*addvar)(DataHandler *, int);
    void (*adddata)(DataHandler *, unsigned char);
    void (*addevent)(DataHandler *);
    void (*claimevent)(DataHandler *);
    void (*done)(DataHandler *);
};

void datahandler_done(DataHandler *dh)
{
    if ( dh->p != 0 )
    {
        while ( dh->p != 8)
        {
            dh->e *= 2;
            ++(dh->p);
        }
        dh->addevent(dh);
    }
}

void datahandler_claimevent(DataHandler *dh)
{
    dh->ep = dh->dp;
    ++(dh->dp);
}

void datahandler_addevent(DataHandler *dh)
{
    dh->buf[dh->ep] = dh->e;
    dh->e=0;
    dh->p=0;
}

void datahandler_adddata(DataHandler *dh, unsigned char d)
{
    dh->buf[(dh->dp)++] = d;
}

void datahandler_addvar(DataHandler *dh, int i)
{
    int j=32768;
    while (!(i&j)) j/=2;
    do
    {
        if (j==1)
        {
            dh->add0(dh);
            return;
        }
        j/=2;
        dh->add1(dh);
        if (i&j) dh->add1(dh);
        else dh->add0(dh);
    }
    while (1);
}

void datahandler_add3(DataHandler *dh, int b)
{
    dh->addbit(dh, b&4);
    dh->addbit(dh, b&2);
    dh->addbit(dh, b&1);
}

void datahandler_addbit(DataHandler *dh, int b)
{
    if (b) dh->add1(dh);
    else dh->add0(dh);
}

void datahandler_add1(DataHandler *dh)
{
    if (dh->p == 0) dh->claimevent(dh);
    dh->e *= 2;
    ++(dh->p);
    ++(dh->e);
    if (dh->p == 8) dh->addevent(dh);
}

void datahandler_add0(DataHandler *dh)
{
    if (dh->p == 0) dh->claimevent(dh);
    dh->e *= 2;
    ++(dh->p);
    if (dh->p == 8) dh->addevent(dh);
}

void datahandler_init(DataHandler *dh, unsigned int length)
{
  dh->ep = 0;
  dh->dp = 0;
  dh->p = 0;
  dh->e = 0;
  dh->buf = (unsigned char *)malloc(length*2);
}

void datahandler_new(DataHandler *dh)
{
  dh->init = datahandler_init;
  dh->add0 = datahandler_add0;
  dh->add1 = datahandler_add1;
  dh->addbit = datahandler_addbit;
  dh->add3 = datahandler_add3;
  dh->addvar = datahandler_addvar;
  dh->adddata = datahandler_adddata;
  dh->addevent = datahandler_addevent;
  dh->claimevent = datahandler_claimevent;
  dh->done = datahandler_done;
}

DataHandler dh;

void initvarcost()
{
    int v = 1,b = 1,r = 1;
    while ( r != 65536 )
    {
        for ( int j=0; j!=r; ++j ) varcost[v++]=b;
        b += 2;
        r *= 2;
    }
}

void createmetadata(unsigned char *d, unsigned int length)
{
    unsigned int i, j;
    unsigned int *last = (unsigned int *)calloc(65536,sizeof(unsigned int));
    /* memset(last,-1,65536*sizeof(unsigned int)); */
    for ( int z = 0; z < 65536; z++ ) last[z] = 65535;
    unsigned int *prev = (unsigned int *)calloc(length+1,sizeof(unsigned int));
    for ( i = 0; i != length; ++i )
    {
        m[i].cpos[0] = m[i].clen[0]=0;
        prev[i] = last[d[i]+d[i+1]*256];
        last[d[i]+d[i+1]*256] = i;
    }
    unsigned int r=-1,t=0;
    for ( i = length-1; i != -1; --i)
    {
        if ( d[i] == r) m[i].reeks = ++t;
        else
        {
            r = d[i];
            m[i].reeks = t = 1;
        }
    }
    for (int bl = 0; bl != 7; ++bl)
    {
        for ( i = 0; i < length; ++i)
        {
            unsigned l,p;
            p = i;
            if (bl)
            {
                m[i].clen[bl] = m[i].clen[bl-1];
                m[i].cpos[bl] = m[i].cpos[bl-1];
                p = i-m[i].cpos[bl];
            }
            while( (p = prev[p])!=-1 )
            {
                if ( i-p > maxlen[bl]) break;
                l=0;
                while (d[p+l] == d[i+l] && (i+l) < length)
                {
                    if (m[i+l].reeks > 1)
                    {
                        if ( (j = m[i+l].reeks) > m[p+l].reeks ) j = m[p+l].reeks;
                        l += j;
                    }
                    else ++l;
                }
                if ( l > m[i].clen[bl] )
                {
                    m[i].clen[bl] = l;
                    m[i].cpos[bl] = i-p;
                }
            }
        }
        // printf(".");
    }
    // printf(" ");
}

int getlen(Pakdata *p, unsigned int q, unsigned int length)
{
    unsigned int i,j,cc,ccc,kc,kmode,kl;
    p[length].cost = 0;
    for ( i = length-1; i != -1; --i)
    {
        kmode = 0;
        kl = 0;
        kc = 9+p[i+1].cost;

        j = m[i].clen[0];
        while ( j > 1 )
        {
            cc = 9 + varcost[j-1] + p[i+j].cost;
            if ( cc < kc )
            {
                kc = cc;
                kmode = 1;
                kl = j;
            }
            --j;
        }

        j = m[i].clen[q];
        if ( q == 1 ) ccc = 9;
        else ccc = 9 + q;
        while ( j > 1 )
        {
            cc = ccc + varcost[j-1] + p[i+j].cost;
            if ( cc < kc )
            {
                kc = cc;
                kmode = 2;
                kl = j;
            }
            --j;
        }

        p[i].cost = kc;
        p[i].mode = kmode;
        p[i].mlen = kl;
    }
    return p[0].cost;
}

void save(Pakdata *p, unsigned char *d, unsigned int length, unsigned int q)
{
    unsigned int i,j;

    // Builds pseudo object
    datahandler_new(&dh);

    dh.init(&dh, length);
    dh.add3(&dh, q-1);
    dh.adddata(&dh, d[0]);
    i=1;
    while( i < length )
    {
        switch ( p[i].mode )
        {
        case 0:
            dh.add0(&dh);
            dh.adddata(&dh, d[i]);
            ++i;
            break;
        case 1:
            dh.add1(&dh);
            dh.addvar(&dh, p[i].mlen-1);
            j = m[i].cpos[0]-1;
            if ( j > 127 ) printf("-j>128-");
            dh.adddata(&dh, j);
            i += p[i].mlen;
            break;
        case 2:
            dh.add1(&dh);
            dh.addvar(&dh, p[i].mlen-1);
            j = m[i].cpos[q]-1;
            if ( j < 128 ) printf("-j<128-");
            j -= 128;
            dh.adddata(&dh, 128|(j&127));
            switch (q)
            {
            case 6:
                dh.addbit(&dh, j&4096);
            case 5:
                dh.addbit(&dh, j&2048);
            case 4:
                dh.addbit(&dh, j&1024);
            case 3:
                dh.addbit(&dh, j&512);
            case 2:
                dh.addbit(&dh, j&256);
                dh.addbit(&dh, j&128);
            case 1:
                break;
            default:
                printf("-2-");
                break;
            }
            i += p[i].mlen;
            break;
        default:
            printf("-?-");
            break;
        }
    }
    for ( i = 0; i != 34; ++i) dh.add1(&dh);
    dh.done(&dh);
}

int createpakdata(unsigned int length)
{
    int i = 1;
    int minlen = length * 1000;
    int minbl = 0;
    for( i = 1; i != 7; ++i)
    {
        p[i] = (Pakdata *)calloc(length+1, sizeof(Pakdata));
        int l = getlen(p[i],i,length);
        if ( l < minlen && i)
        {
            minlen = l;
            minbl = i;
        }
        // printf(".");
    }
    return minbl;
}

unsigned char *pletter_encode(short int numScreen, unsigned char *cPtr, unsigned int *nBytes)
{
    int minbl;
    unsigned char *cSrc;

    cSrc = (unsigned char *)malloc(*nBytes+1);
    memcpy(cSrc, cPtr, *nBytes);
    cSrc[*nBytes] = 0;
    m = (Metadata *)calloc(*nBytes+1,sizeof(*m));
    initvarcost();
    createmetadata(cSrc, *nBytes);
    minbl = createpakdata(*nBytes);
    save(p[minbl], cSrc, *nBytes, minbl);
    *nBytes = dh.dp;
    return dh.buf;
}

