FROM nginx:1.22.1

# 安裝必要的構建工具和依賴
RUN apt-get update && apt-get install -y \
    wget \
    libpcre3 \
    libpcre3-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    gcc \
    make \
    libtool \
    automake \
    autoconf

RUN apt-get update && apt-get install -y libmaxminddb0 libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

# 下載 Nginx 源碼
RUN wget http://nginx.org/download/nginx-1.22.1.tar.gz \
    && tar zxf nginx-1.22.1.tar.gz

# 下載 ngx_http_geoip2_module
RUN wget https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/3.4.tar.gz \
    && tar zxf 3.4.tar.gz

# 編譯 Nginx 並包含 GeoIP2 模組
RUN cd nginx-1.22.1 \
    && ./configure --with-compat --add-dynamic-module=../ngx_http_geoip2_module-3.4 \
    && make modules

# 複製編譯好的模組到 Nginx 模組目錄
RUN cp nginx-1.22.1/objs/ngx_http_geoip2_module.so /etc/nginx/modules/ \
    && rm -rf nginx-1.22.1

ADD ./GeoLite2/* /etc/nginx/GeoLite2/

CMD ["nginx", "-g", "daemon off;"]
