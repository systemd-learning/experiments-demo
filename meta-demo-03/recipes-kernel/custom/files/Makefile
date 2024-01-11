obj-m += demo.o
#The new sensor driver needs to be added manually

SRC := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC)

modules_install:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install

.PHONY: clean
clean:
	-rm -f *.o *.ko *.order *.symvers *.mod.c

