CFLAGS = -fno-exceptions -fno-rtti -O2 `pkg-config lua5.1 --cflags` -DWITH_URANDOM

all:
	gcc $(CFLAGS) -o xupnpd main.cpp soap.cpp mem.cpp mcast.cpp luaxlib.cpp luaxcore.cpp `pkg-config lua5.1 --libs` -ldl
	strip xupnpd

lib:
	gcc $(CFLAGS) -shared -o luaxlib.so mem.cpp soap.cpp luaxlib.cpp