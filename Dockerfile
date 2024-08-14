# multi-stage builds
FROM nginx:1.22.1 AS builder-geoip2

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
    && ./configure --with-compat --with-stream --add-dynamic-module=../ngx_http_geoip2_module-3.4 \
    && make modules

# 複製編譯好的模組到 Nginx 模組目錄
RUN cp nginx-1.22.1/objs/ngx_http_geoip2_module.so nginx-1.22.1/objs/ngx_stream_geoip2_module.so /etc/nginx/modules/


# multi-stage builds
FROM nginx:1.22.1 AS release

# 安裝 libmaxminddb, geoip2需要
RUN apt-get update && apt-get install -y libmaxminddb0 libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder-geoip2 /etc/nginx/modules/ngx_http_geoip2_module.so /etc/nginx/modules/ngx_stream_geoip2_module.so /usr/lib/nginx/modules/

RUN mkdir -p /etc/nginx/GeoLite2
ADD ./GeoLite2/* /etc/nginx/GeoLite2/
ADD nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]

