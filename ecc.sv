`define PWIDTH \
((DWIDTH>=  1)?3:0) + ((DWIDTH>=  2)?1:0) + ((DWIDTH>=  8)?1:0) + ((DWIDTH>= 12)?1:0) + \
((DWIDTH>= 27)?1:0) + ((DWIDTH>= 58)?1:0) + ((DWIDTH>=121)?1:0) + ((DWIDTH>=248)?1:0) + \
((DWIDTH>=503)?1:0)

module eccEncode #(parameter DWIDTH=128)(
    input logic[DWIDTH-1:0] din,
    output logic[`PWIDTH+DWIDTH-1:0] dout
);
always_comb begin
    integer dIdx = DWIDTH - 1;
    integer pIdx = `PWIDTH - 1;
    for(integer i=`PWIDTH+DWIDTH-1; i>=0; i=i-1)begin
        if(i==(`PWIDTH+DWIDTH-1))begin
            dout[i] = 0;
            for(integer j=`PWIDTH+DWIDTH-1; j>=0; j=j-1) if((((j>>(pIdx-1))%2)==1) && (j!=i)) dout[i] = dout[i] ^ dout[j];
            pIdx = pIdx - 1;
        end
        else if(i==0)begin
            dout[i] = 0;
            for(integer j=`PWIDTH+DWIDTH-1; j>=0; j=j-1) if(j!=i) dout[i] = dout[i] ^ dout[j];
            pIdx = pIdx - 1;
        end
        else if(i==((1<<pIdx)-1))begin
            dout[i] = 0;
            for(integer j=`PWIDTH+DWIDTH-1; j>=0; j=j-1) if((((j>>(pIdx-1))%2)==1) && (j!=i)) dout[i] = dout[i] ^ dout[j];
            pIdx = pIdx - 1;
        end
        else begin
            dout[i] = din[dIdx];
            dIdx = dIdx - 1;
        end
    end
end
endmodule

module eccDecode #(parameter DWIDTH=128)(
    input logic[`PWIDTH+DWIDTH-1:0] din,
    output logic[DWIDTH-1:0] doutNotFixed,
    output logic[DWIDTH-1:0] doutFixed,
    output logic singleError,
    output logic multiError
);
logic[$clog2(`PWIDTH+DWIDTH)-1:0] errorIdx;
always_comb begin
    for(integer i=$clog2(`PWIDTH+DWIDTH)-1; i>=0; i=i-1)begin
        errorIdx[i] = 0;
        for(integer j=`PWIDTH+DWIDTH-1; j>=0; j=j-1) if(((j>>i)%2)==1) errorIdx[i] = errorIdx[i] ^ din[j];
    end
    singleError = 0;
    for(integer j=`PWIDTH+DWIDTH-1; j>=0; j=j-1) singleError = singleError ^ din[j];
    multiError = (!singleError) && (errorIdx!=0);
end
always_comb begin
    integer dIdx = DWIDTH - 1;
    integer pIdx = `PWIDTH - 1;
    for(integer i=`PWIDTH+DWIDTH-1; i>=0; i=i-1)begin
        if((i==(`PWIDTH+DWIDTH-1)) || (i==0) || (i==((1<<pIdx)-1))) pIdx = pIdx - 1;
        else begin
            doutNotFixed[dIdx] = din[i];
            doutFixed[dIdx] = (singleError && (errorIdx==i)) ? (~din[i]) : din[i];
            dIdx = dIdx - 1;
        end
    end
end
endmodule
