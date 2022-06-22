%MD5:message-digest algorithm 5 
%%�������
%text���������ⳤ�ȵ�ascii���ģ�ascii����
%digest������md5�㷨�õ���ժҪ,16�������
%������С��ģʽ����
clear all

%ͨ��twincat���뱾��cpu��ŵ�md5�룬�����������matlabʶ��ı������Ӧ�����1���������0
fid=importdata('password_cpu_md5.csv');%��ȡ�����ֵ�csv
fid=cell2mat(fid);%cellתchar



%%%%��ȡ����CPU�����壬Ӳ�̣�bios���к�
% cmd1 = 'wmic baseboard get serialnumber';% �������к�
% cmd2 = 'wmic diskdrive get serialnumber';% Ӳ�����к�
cmd3 = 'wmic cpu get processorid';% CPU���к�
% cmd4 = 'wmic bios get serialnumber';% BIOS���к�

% [~, result] = system(cmd1);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_baseboard = fields{2};% �������к�
% [~, result] = system(cmd2);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_diskdrive = fields{2};% Ӳ�����к�
[~, result] = system(cmd3);
fields = textscan( result, '%s', 'Delimiter', '\n' );
fields = strtrim(fields{1});
serialID_cpu = fields{2};% CPU���к�
% [~, result] = system(cmd4);
% fields = textscan( result, '%s', 'Delimiter', '\n' );
% fields = strtrim(fields{1});
% serialID_bios = fields{2};% BIOS���к�

text=serialID_cpu;

%������ݱ��
X=[0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15;%512λ������x[k]ʹ��˳���
    1 6 11 0 5 10 15 4 9 14 3 8 13 2 7 12;
    5 8 11 14 1 4 7 10 13 0 3 6 9 12 15 2;
    0 7 14 5 12 3 10 1 8 15 6 13 4 11 2 9];

%ѭ����λ��
Cyclic=[7 12 17 22;5 9 14 20;4 11 16 23;6 10 15 21];

%��������ʼ��
%A=0x67452301,B=0xefcdab89,C=0x98badcfe,D=0x10325476С��ģʽ����
A=1732584193;B=4023233417;C=2562383102;D=271733878;%��Ӧ10��������
% �������
L_ascii = length(text);%��ȡ�������ĳ���
L_fill = (448-mod(L_ascii*8,512))/8;%������ֽ��� %mod�����������ȡģ���㣩
L_total = L_ascii+L_fill+8;
if L_fill<0%������һ��
    L_total = L_total+64;
    L_fill = L_fill+64;
end
L_text = L_ascii*8;%����bit�����ȣ��������ݳ����ݲ��ᳬ��2^64λ
text_buf = zeros(1,L_total);%�������ֽڴ洢
for i=1:L_ascii%���ֶ���
    text_buf(i) = char(text(i));
end
text_buf(L_ascii+1) = 128;%���0x80
for i=2+L_ascii:L_ascii+L_fill%��0
    text_buf(i) = 0;
end
%bitget(a,8:-1:1)����˼�� ���Ȱ�ʮ��������aת���ɶ��������֣�Ȼ�󰴴ӵڰ�λ����λһֱ����һλ���
%�ҵ������ǽ�aת����Ϊ�̶��Ķ����������涨����ĳ��Ⱦ��ǰ�λ��ǰ�߲���
for i=1:8%��䳤��
    bits = bitget(L_text,i*8:-1:i*8-7);bits_str = num2str(bits);
    pos = bits_str~=' ';%��ʾ���������˱��ʽ�����ʱ�����Ϊ1
    text_buf(L_total-8+i)=bin2dec(bits_str(pos));%bin2dec������תʮ����
end
% ժҪ����
%�����ݷ�Ϊn��512λ����64���ֽڣ�ÿ�μ���һ��64�ֽڣ�ÿ��64�ֽ��ַ�Ϊ16С�ݣ�ÿһС�����ֽ�
L_cycle = L_total/64;%�ܹ���Ҫ����������
for i=1:L_cycle
    A0_tmp=A;B0_tmp=B;C0_tmp=C;D0_tmp=D;%�����ݴ�
    XK=reshape(text_buf((i-1)*64+1:i*64),4,16); %��ÿ��64�ֽ�ת��4��16����
    for j=1:4%��������
       switch j%ѡ�����õ��߼�����
            case 1 
                for m=1:16%ÿ��16����������
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%�����ݴ�
                    A=D_tmp;C=B_tmp;D=C_tmp;%����
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=(b&c)|((~b)&d);%�߼���������
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%�߼�������������ֵ
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%���Һ�������ֵ
                    %num_X�ò���ʹ�õ�32λ�ֶ�Ӧ��ֵ��С��ģʽ
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %ģ2^32�ӣ��о��α��ϸ������Ǹ���ͼ��Щ���壬һ��ʼʹ����Ϊ��ģ2�ӣ��Ķ������Դ��󣬸����˹���
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%ѭ����λ
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%ģ2^32��
                end
            case 2 
                for m=1:16%ÿ��16����������
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%�����ݴ�
                    A=D_tmp;C=B_tmp;D=C_tmp;%����
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=(b&d)|(c&(~d));%�߼���������
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%�߼�������������ֵ
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%���Һ�������ֵ
                    %num_X�ò���ʹ�õ�32λ�ֶ�Ӧ��ֵ��С��ģʽ
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %ģ2^32�ӣ��о��α��ϸ������Ǹ���ͼ��Щ���壬һ��ʼʹ����Ϊ��ģ2�ӣ��Ķ������Դ��󣬸����˹���
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%ѭ����λ
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%ģ2^32��
                end
            case 3 
                for m=1:16%ÿ��16����������
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%�����ݴ�
                    A=D_tmp;C=B_tmp;D=C_tmp;%����
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=bitxor(bitxor(b,c),d);%�߼���������
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%�߼�������������ֵ
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%���Һ�������ֵ
                    %num_X�ò���ʹ�õ�32λ�ֶ�Ӧ��ֵ��С��ģʽ
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %ģ2^32�ӣ��о��α��ϸ������Ǹ���ͼ��Щ���壬һ��ʼʹ����Ϊ��ģ2�ӣ��Ķ������Դ��󣬸����˹���
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%ѭ����λ
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%ģ2^32��
                end
            case 4 
                for m=1:16%ÿ��16����������
                    A_tmp=A;B_tmp=B;C_tmp=C;D_tmp=D;%�����ݴ�
                    A=D_tmp;C=B_tmp;D=C_tmp;%����
                    b=bitget(B_tmp,32:-1:1);
                    c=bitget(C_tmp,32:-1:1);
                    d=bitget(D_tmp,32:-1:1);
                    bits=bitxor(c,b|(~d));%�߼���������
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));%�߼�������������ֵ
                    num_T=floor(2^32*abs(sin((j-1)*16+m)));%���Һ�������ֵ
                    %num_X�ò���ʹ�õ�32λ�ֶ�Ӧ��ֵ��С��ģʽ
                    num_X = bitshift(XK(4,X(j,m)+1),24)+bitshift(XK(3,X(j,m)+1),16)+bitshift(XK(2,X(j,m)+1),8)+XK(1,X(j,m)+1);
                    %ģ2^32�ӣ��о��α��ϸ������Ǹ���ͼ��Щ���壬һ��ʼʹ����Ϊ��ģ2�ӣ��Ķ������Դ��󣬸����˹���
                    B=mod(A_tmp+num_B+num_T+num_X,2^32);
                    bits = bitget(B,32:-1:1);
                    bits = circshift(bits,[0,-1*Cyclic(j,mod(m-1,4)+1)]);%ѭ����λ
                    bits_str = num2str(bits);pos = bits_str~=' ';num_B=bin2dec(bits_str(pos));
                    B=mod(num_B+B_tmp,2^32);%ģ2^32��
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
%С��ģʽ��������ȡ˳��
for i=1:4
    for j=1:4
        digest=[digest,num2str(dec2hex(bin2dec(digest_str(i*32+1-j*8:i*32+4-j*8))))]; 
        digest=[digest,num2str(dec2hex(bin2dec(digest_str(i*32+5-j*8:i*32+8-j*8))))]; 
    end
end

%ͨ��twincat���뱾��cpu��ŵ�md5�룬�����������matlabʶ��ı������Ӧ�����1���������0
if fid==digest
    a=1;
else
    a=0;
end

csvwrite('Output.csv',[a]);
csvwrite('Output1.csv',[fid;digest]);