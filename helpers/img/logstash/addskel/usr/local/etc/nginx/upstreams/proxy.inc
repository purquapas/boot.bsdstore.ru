proxy_set_header   Host             $host;
proxy_set_header   X-Real-IP        $remote_addr;
#proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;

client_max_body_size       12m;
client_body_buffer_size    512k;

#client_body_temp_path      /var/nginx/client_body_temp;
proxy_connect_timeout      20;
proxy_send_timeout         60;
proxy_read_timeout         60;
#proxy_send_lowat           12000;

proxy_buffer_size          256k;
proxy_buffers              16 256k;
proxy_busy_buffers_size    256k;
proxy_temp_file_write_size 256k;
#proxy_temp_path            /var/nginx/proxy_temp;

proxy_headers_hash_max_size 1024;
proxy_headers_hash_bucket_size 512;
