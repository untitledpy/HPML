%MD5:message-digest algorithm 5 
%%输入输出
%text：输入任意长度得ascii明文，ascii输入
%digest：运行md5算法得到得摘要,16进制输出
%运算以小端模式进行
clear all

%通过twincat输入本机cpu编号的md5码，若输入的码与matlab识别的本机码对应则输出1，否则输出0
fid=importdata('password_cpu_md5.csv');%读取非数字的csv
fid=cell2mat(fid);%cell转char



%%%%读取本机CPU，主板，硬盘，bios序列号
% cmd1 = 'wmic baseboard get serialnumber';% 主板序列号
% cmd2 = 'wmic diskdrive get serialnumber';% 硬盘序列号
cmd3 = 'wmic cpu get processorid';% CPU序列号
% cmd4 = 'wmic bios get serialnumber';% BIOS序列号

% [~, result] = system(cmd1);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_baseboard = fields{2};% 主板序列号
% [~, result] = system(cmd2);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_diskdrive = fields{2};% 硬盘序列号
[~, result] = system(cmd3);
fields = textscan( result, '%s', 'Delimiter', '\n' );
fields = strtrim(fields{1});
serialID_cpu = fields{2};% CPU序列号
% [~, result] = system(cmd4);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_bios = fields{2};% BIOS序列号

text=serialID_cpu;

%相关数据表格
X=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15;%512位分组中x[k]使用顺序表
    1 6 11 0 5 10 15 4 9 14 3 8 13 2 7 12;
    5 8 11 14 1 4 7 10 13 0 3 6 9 12 15 2;
    0 7 14 5 12 3 10 1 8 15 6 13 4 11 2 9];

%循环移位表
Cyclic=[7 12 17 22;5 9 14 20;4 11 16 23;6 10 15 21];

%缓冲区初始化
%A=0x67452301,B=0xefcdab89,C=0x98badcfe,D=0x10325476小端模式数据
A=1732584193;B=4023233417;C=2562383102;D=271733878;%对应10进制数据
% 数据填充
L_ascii = length(text);%获取输入明文长度
L_fill = (448-mod(L_ascii*8,512))/8;%待填充字节数 %mod除后的余数（取模运算）
L_total = L_ascii+L_fill+8;
if L_fill<0%再扩充一段
    L_total = L_total+64;
    L_fill = L_fill+64;
end
L_text = L_ascii*8;%数据bit数长度，假设数据长度暂不会超过2^64位
text_buf = zeros(1,L_total);%数据以字节存储
for i=1:L_ascii%文字读入
    text_buf(i) = char(text(i));
end
text_buf(L_ascii+1) = 128;%填充0x80
for i=2+L_ascii:L_ascii+L_fill%填0
    text_buf(i) = 0;
end
%bitget(a,8:-1:1)的意思是 首先把十进制数字a转化成二进制数字，然后按从第八位第七位一直到第一位输出
%我的理解就是将a转化成为固定的二进制数，规定输出的长度就是八位，前边补零
for i=1:8%填充长度
    bits = bitget(L_text,i*8:-1:i*8-7);bits_str = num2str(bits);
    pos = bits_str~=' ';%表示当左右两端表达式不相等时，结果为1
    text_buf(L_total-8+i)=bin2dec(bits_str(pos));%bin2dec二进制转十进制
end
% 摘要运算
%将数据分为n个512位，即64个字节，每次计算一份64字节，每份64字节又分为16小份，每一小份四字节
L_cycle = L_total/64;%总共需要的运算轮数
for i=1:L_cycle
    A0_tmp=A;B0_tmp=B;C0_tmp=C;D0_tmp=D;%数据暂存
    XK=reshape(text_buf((i-1)*64+1:i*64),4,16); %将每份64字节转成4×16数组
    for j=1:4%四轮运算
       switch j%选择处理用的逻辑函数
            case 1 
                for m=1:16%每轮16步迭代过程
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%数据暂存
                    A=D_tmp;C=B_tmp;D=C_tmp;%交换
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=(b&c)|((~b)&d);%逻辑函数处理
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%逻辑函数处理结果的值
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%正弦函数运算值
                    %num_X该步所使用的32位字对应数值，小端模式
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %模2^32加，感觉课本上给出的那个框图有些歧义，一开始使我以为是模2加，阅读了许多源码后，更正了过来
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%循环移位
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%模2^32加
                end
            case 2 
                for m=1:16%每轮16步迭代过程
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%数据暂存
                    A=D_tmp;C=B_tmp;D=C_tmp;%交换
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=(b&d)|(c&(~d));%逻辑函数处理
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%逻辑函数处理结果的值
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%正弦函数运算值
                    %num_X该步所使用的32位字对应数值，小端模式
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %模2^32加，感觉课本上给出的那个框图有些歧义，一开始使我以为是模2加，阅读了许多源码后，更正了过来
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%循环移位
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%模2^32加
                end
            case 3 
                for m=1:16%每轮16步迭代过程
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%数据暂存
                    A=D_tmp;C=B_tmp;D=C_tmp;%交换
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=bitxor(bitxor(b,c),d);%逻辑函数处理
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%逻辑函数处理结果的值
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%正弦函数运算值
                    %num_X该步所使用的32位字对应数值，小端模式
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %模2^32加，感觉课本上给出的那个框图有些歧义，一开始使我以为是模2加，阅读了许多源码后，更正了过来
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%循环移位
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%模2^32加
                end
            case 4 
                for m=1:16%每轮16步迭代过程
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%数据暂存
                    A=D_tmp;C=B_tmp;D=C_tmp;%交换
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=bitxor(c,b|(~d));%逻辑函数处理
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%逻辑函数处理结果的值
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%正弦函数运算值
                    %num_X该步所使用的32位字对应数值，小端模式
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %模2^32加，感觉课本上给出的那个框图有些歧义，一开始使我以为是模2加，阅读了许多源码后，更正了过来
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%循环移位
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%模2^32加
                end
        end

    end
    A=mod(A+A0_tmp,2^32);
    B=mod(B+B0_tmp,2^32);
    C=mod(C+C0_tmp,2^32);
    D=mod(D+D0_tmp,2^32);
end

digest_tmp=[bitget(A,32:-1:1) bitget(B,32:-1:1) bitget(C,32:-1:1) bitget(D,32:-1:1)];
digest_str=num2str(digest_tmp); 
pos= digest_str~=' ';
digest_str=digest_str(pos);
digest = [];
%小端模式，更正读取顺序
for i=1:4
    for j=1:4
        digest=[digest,num2str(dec2hex(bin2dec(digest_str(i*32+1-j*8:i*32+4-j*8))))]; 
        digest=[digest,num2str(dec2hex(bin2dec(digest_str(i*32+5-j*8:i*32+8-j*8))))]; 
    end
end

%通过twincat输入本机cpu编号的md5码，若输入的码与matlab识别的本机码对应则输出1，否则输出0
if fid==digest
    a=1;
else
    a=0;
end

csvwrite('Output.csv',[a]);
csvwrite('Output1.csv',[fid;digest]);