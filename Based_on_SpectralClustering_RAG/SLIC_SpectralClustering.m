clc
clear
close all
tic()
%��MATLAB�в���GitHub
%% [0] �������
T_threshold=2.3;          %��ֵ���� 321*421��ʱ��,ȡֵ 2.3 Ч���ܺ�,
num_clusters = 20;      %�������� 321*421��ʱ��,ȡֵ 20
sigma = 100;            %�����޸ģ���֪����������
RGB_LAB_flag=0;         %ѡ���� LAB �ռ�(1)���л����� RGB �ռ�(0)����

if RGB_LAB_flag==1
    T_threshold=0.6;
else
    T_threshold=0.6;
end
%% [1] SLIC�����طָ����ɳ����ؿ�

SuperpixelsNum=500;     %����������
CompactnessFactor=20;   %���ܶ�
image=imread('1.jpg');  %ԭʼͼ��
[image_width,image_heigh,image_d]=size(image);
%segmentsΪ�����صı�ǩ��numlabelsΪ����������
[segments, numlabels]=mex_SLIC_fun(image, SuperpixelsNum, CompactnessFactor);
segments=segments+1;    %Ϊ�˷�������;���洢����+1

%% [2] Spectral Clustering�׾���

%constant,m���ƺ�ͼƬ��С�й�ϵ,�޸�ͼƬ�ǵ��޸�m
m=100;
SW=sqrt(image_width*image_heigh)/m;
image_lab=rgb2lab(image);           %ɫ��ת��RGB TO LAB
image_lab_L=image_lab(:,:,1);
image_lab_A=image_lab(:,:,2);
image_lab_B=image_lab(:,:,3);
image_R=image(:,:,1);
image_G=image(:,:,2);
image_B=image(:,:,3);
D=zeros(numlabels,numlabels);       %���ɾ����������

%���ÿ�������ؿ�� 5-D ����LABXY,�����ر�ǩ��0��ʼ

%% [3] �����������ؿ�Ļ�����Ϣ�ľ�ֵ,LABXY

for k=1:numlabels
    [row_superpixel,col_superpixel]=find(segments==k);     %��ǩΪk�ĳ����صĺ�������λ��
    position_superpixel=[row_superpixel,col_superpixel];    %�����ؿ��λ����Ϣ
    mean_X(k)=mean(col_superpixel);                         %��ÿ�������ؿ������ƽ��ֵ
    mean_Y(k)=mean(row_superpixel);
    index_L=sub2ind(size(image_lab_L),row_superpixel,col_superpixel);
    index_A=sub2ind(size(image_lab_A),row_superpixel,col_superpixel);
    index_B=sub2ind(size(image_lab_B),row_superpixel,col_superpixel);
    mean_L(k)=mean(image_lab_L(index_L));                   %��ÿ�������ؿ� LAB ����������ƽ��ֵ
    mean_A(k)=mean(image_lab_A(index_A));
    mean_B(k)=mean(image_lab_B(index_B));
    mean_RGB_R(k)=mean(image_R(index_L));                   %��ÿ�������ؿ� LAB ����������ƽ��ֵ
    mean_RGB_G(k)=mean(image_G(index_A));
    mean_RGB_B(k)=mean(image_B(index_B));
end

%% [4] ������������� Dij

for i=1:numlabels
    for j=1:numlabels
        Color_D=(mean_L(i)-mean_L(j)).^2+(mean_A(i)-mean_A(j)).^2+(mean_B(i)-mean_B(j)).^2;
        Distance_D=((mean_X(i)-mean_X(j))./SW).^2+((mean_Y(i)-mean_Y(j))./SW).^2;
        D(i,j)=sqrt(Color_D+Distance_D);
    end
end


%% [5] Ѱ�����ⳬ���ؾ��������5�������ؿ鲢���ֵ
t=5;                                                  %������ i ����ļ��������صļ��ϵ�������������ȡ5
for i=1:numlabels
    [D_sort(i,:),D_index(i,:)]=sort(D(i,:));          %�Ծ�������������ȡ��С��5��ֵ
    T_neighbor_index(i,:)=D_index(i,1:t+1);           %���� i �����5�������ص�����
    T_neighbor_value(i,:)=D_sort(i,1:t+1);            %���� i �����5�������ص�ֵ
    sigma_i(i)=mean(T_neighbor_value(i,:));
end


%% [6] �������ƶȾ���

for i=1:numlabels
    for j=1:numlabels
        if T_neighbor_index(i,:)~=j
            S(i,j)=0;
        else
            S(i,j)=exp((-D(i,j).^2)/(2*sigma_i(i)*sigma_i(j)));
        end
    end
end

%% [7] �����׾���

cluster_labels=sc(S,sigma,num_clusters);                    %����ֵ��ʾ��ÿһ�������ر�ǩ�����ľ����ǩ
segments_cluster=100*(ones(size(segments)));
for i=1:numlabels
    [row_superpixel,col_superpixel]=find(segments==i);
    index_cluster=sub2ind(size(image_lab_L),row_superpixel,col_superpixel);
    segments_cluster(index_cluster)=cluster_labels(i);
end
for i=1:num_clusters
    superpixel_cluster_labels{i}=find(cluster_labels==i);   %�洢ÿһ����������Щ�����ؿ�
end
segments_cluster=int32(segments_cluster);
segmentlabel2image_fun(image,segments_cluster,'�׾���ϲ����');             %��ʾͼ��

%% [8] �õ����ڳ����ؿ�����ھ����index

%���ڳ����ؿ��index
for i=1:numlabels
    value = i;      %Ҫ�жϵĳ����ؿ�
    adj = [0 1 0; 1 0 1; 0 1 0];
    mask = conv2(double(segments==i),adj,'same')>0;
    temp=unique(segments(mask));
    temp_row=temp';
    %ɾ������
    self_index=find(temp_row==i);
    temp_row(self_index)=[];
    %�õ�ÿ�������ص��ڽӳ����ص�index
    result_SLIC{i}=temp_row;
end
%���ɳ����ص��ڽӾ���A
superpixel_A=zeros(numlabels,numlabels);
for i=1:numlabels
    for j=1:numlabels
        superpixel_A(i,result_SLIC{i})=1;
    end
end
%���ھ����index
for i=1:num_clusters
    value = i;      %Ҫ�жϵĳ����ؿ�
    adj = [0 1 0; 1 0 1; 0 1 0];
    mask = conv2(double(segments_cluster==i),adj,'same')>0;
    temp=unique(segments_cluster(mask));
    temp_row=temp';
    %ɾ������
    self_index=find(temp_row==i);
    temp_row(self_index)=[];
    %�õ�ÿ�������ص��ڽӳ����ص�index
    result_cluster{i}=temp_row;
end
%���ɾ�����ڽӾ���A
cluster_A=zeros(numlabels,numlabels);
for i=1:num_clusters
    for j=1:num_clusters
        cluster_A(i,result_cluster{i})=1;
    end
end
%% [9] �ҵ����� i �;��� j ���ڱ߽��ϵĳ����ؿ�����Щ

for i=1:num_clusters
    for j=1:num_clusters
        if any(result_cluster{i}==j)
            %˵������ i �� j ����,�����жϾ��� i �� j �еĳ������Ƿ�����
            %���ȿ����� i �� j �д�����Щ������
            cluster_i_superpixel=superpixel_cluster_labels{i};
            cluster_j_superpixel=superpixel_cluster_labels{j};
            length_i=length(cluster_i_superpixel);
            length_j=length(cluster_j_superpixel);
            k=1;
            for m=1:length_i
                for n=1:length_j
                    if superpixel_A(cluster_i_superpixel(m),cluster_j_superpixel(n))==1     %˵���������ڽ�
                        cluster_i_j{i,j,k}=[cluster_i_superpixel(m),cluster_j_superpixel(n)];
                        k=k+1;  %�ڽӵĳ����ص�����
                    end
                end
            end
            %��¼�ڽӾ��������
            num_adjacent_superpixel(i,j)=k-1;
            
        end
    end
end

%% [10] ������ֵ T

for i=1:numlabels
    temp=result_SLIC{i};
    for j=1:length(temp)
        if RGB_LAB_flag==1
            Color_cluster_superpixel_D=(mean_L(i)-mean_L(temp(j))).^2+(mean_A(i)-mean_A(temp(j))).^2+(mean_B(i)-mean_B(temp(j))).^2;
            D_cluster(j)=sqrt(Color_cluster_superpixel_D);
        else
            Color_cluster_superpixel_D=(mean_RGB_R(i)-mean_RGB_R(temp(j))).^2+(mean_RGB_G(i)-mean_RGB_G(temp(j))).^2+(mean_RGB_B(i)-mean_RGB_B(temp(j))).^2;
            D_cluster(j)=sqrt(Color_cluster_superpixel_D);
        end
    end
    MaxEdges(i)=max(D_cluster);
end
if max(MaxEdges)>10
    T=mean(MaxEdges)-std(MaxEdges)/2;
else
    T=10;
end

%% [11] �����ڽ�ͼ�Ĳ����ƶ�

% temp_flag=0;
% [a,b,c]=size(cluster_i_j);
% for i=1:a
%     for j=1:b
%         for k=1:c
%             temp=cluster_i_j{i,j,k};
%             if isempty(cluster_i_j{i,j,k})==0   %�����ڽ���
%                 Color_cluster_superpixel_D_temp=(mean_L(temp(1))-mean_L(temp(2))).^2+(mean_A(temp(1))-mean_A(temp(2))).^2+(mean_B(temp(1))-mean_B(temp(2))).^2;
%                 E_cluster(k)=sqrt(Color_cluster_superpixel_D_temp);
%                 temp_flag=1;
%             end
%         end
%         if temp_flag==1
%             D_Ri_Rj(i,j)=mean(E_cluster);
%             temp_flag=0;
%             E_cluster=0;
%         else
%             D_Ri_Rj(i,j)=0;
%             E_cluster=0;
%             temp_flag=0;
%         end
%     end
% end
%% [10] ������ֵ���������ڽ�ͼ���� A

% A=zeros(num_clusters);
% for i=1:num_clusters
%     for j=1:num_clusters
%         if D_Ri_Rj(i,j)<T
%             A(i,j)=1;
%         else
%             A(i,j)=0;
%         end
%     end
% end

%% [11] ���վ���A�ϲ�����


%% [12] ��ʱ���� 11 ,ֱ�ӵ��� python �е� RAG �������кϲ�����

image_python = reshape(image,[1 numel(image)]);                 %��image����ת����python�ܽ��ܵ�����
segments_cluster_python = reshape(segments_cluster,[1 numel(segments_cluster)]);
image_python= py.numpy.array(image_python);
segments_cluster_python= py.numpy.array(segments_cluster_python);

%����ʹ��LAB��ɫ�ռ�
image_lab_python = reshape(image_lab,[1 numel(image_lab)]);                 %��image����ת����python�ܽ��ܵ�����
image_lab_python= py.numpy.array(image_lab_python);
if RGB_LAB_flag==1
    rag_cluster=py.skimage.future.graph.rag_mean_color(image_lab_python,segments_cluster_python);      %���ɾ���� RAG ͼ
else
    rag_cluster=py.skimage.future.graph.rag_mean_color(image_python,segments_cluster_python);      %���ɾ���� RAG ͼ
end
rag_segments=py.skimage.future.graph.cut_threshold(segments_cluster_python,rag_cluster,T_threshold*T);     %���� RAG �µ�segments

rag_segments_list=py.list(rag_segments);        %ת���� python ��list����,��������

cP = cell(rag_segments_list);
rag_segments_int32 = cellfun(@int32,cP);     %ת����matlab�ľ�������int32

rag_segments_int32_reshap = reshape(rag_segments_int32,[image_width image_heigh]);  %�ı��С
rag_segments_int32_reshap=rag_segments_int32_reshap+1;
segmentlabel2image_fun(image,rag_segments_int32_reshap,'RAG �ϲ����');

time=toc()