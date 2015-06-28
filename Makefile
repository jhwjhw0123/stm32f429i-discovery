# Name of the binaries.
PROJECT=blinky

######################################################################
#                         SETUP SOURCES                              #
######################################################################


# This is the directory containing the firmware package,
# the unzipped folder downloaded from here:
# http://www.st.com/web/catalog/tools/FM116/SC959/SS1532/PF259090
STM_DIR=../STM32F429I-Discovery_FW_V1.0.1

# This is where the source files are located,
# which are not in the current directory
# (the sources of the standard peripheral library, which we use)
STM_PERIPH_DIR = $(STM_DIR)/Libraries/STM32F4xx_StdPeriph_Driver/src

# Tell make to look in that folder if it cannot find a source
# in the current directory
vpath %.c $(STM_PERIPH_DIR)

# My source file
SRCS   = main.c

# Contains initialisation code and must be compiled into
# our project. This file is in the current directory and
# was writen by ST.
SRCS  += system_stm32f4xx.c

# These source files implement the functions we use.
# make finds them by searching the vpath defined above.
SRCS  += stm32f4xx_rcc.c 
SRCS  += stm32f4xx_gpio.c

# Startup file written by ST
# The assembly code in this file is the first one to be
# executed. Normally you do not change this file.
SRCS += $(STM_DIR)/Libraries/CMSIS/Device/ST/STM32F4xx/Source/Templates/TrueSTUDIO/startup_stm32f429_439xx.s

# The header files we use are located here
INC_DIRS  = $(STM_DIR)/Utilities/STM32F429I-Discovery
INC_DIRS += $(STM_DIR)/Libraries/CMSIS/Include
INC_DIRS += $(STM_DIR)/Libraries/CMSIS/Device/ST/STM32F4xx/Include
INC_DIRS += $(STM_DIR)/Libraries/STM32F4xx_StdPeriph_Driver/inc
INC_DIRS += .

# in case we have to many sources and don't want 
# to compile all sources every time
# OBJS = $(SRCS:.c=.o)

######################################################################
#                         SETUP TOOLS                                #
######################################################################


TOOLCHAIN = arm-none-eabi

# The tool we use
CC      = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy
GDB     = $(TOOLCHAIN)-gdb

## Preprocessor options

# directories to be searched for header files
INCLUDE = $(addprefix -I,$(INC_DIRS))

# #defines needed when working with the STM library
DEFS    = -DSTM32F429_439xx -DUSE_STDPERIPH_DRIVER
# if you use the following option, you must implement the function 
#    assert_failed(uint8_t* file, uint32_t line)
# because it is conditionally used in the library
# DEFS   += -DUSE_FULL_ASSERT

## Compiler options
CFLAGS  = -ggdb
# please do not optimize anything because we are debugging
CFLAGS += -O0 
CFLAGS += -Wall -Wextra -Warray-bounds
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m4 -mthumb-interwork
CFLAGS += -mfloat-abi=hard -mfpu=fpv4-sp-d16

## Linker options
# tell ld which linker file to use
# (this file is in the current directory)
LFLAGS  = --specs=nosys.specs -Tstm32_flash.ld


######################################################################
#                         SETUP TARGETS                              #
######################################################################

.PHONY: $(PROJECT)
$(PROJECT): $(PROJECT).elf

$(PROJECT).elf: $(SRCS)
	$(CC) $(INCLUDE) $(DEFS) $(CFLAGS) $(LFLAGS) $^ -o $@ 
	$(OBJCOPY) -O ihex $(PROJECT).elf   $(PROJECT).hex
	$(OBJCOPY) -O binary $(PROJECT).elf $(PROJECT).bin

clean:
	rm -f *.o $(PROJECT).elf $(PROJECT).hex $(PROJECT).bin

# Flash the STM32F4
flash: 
	st-flash write $(PROJECT).bin 0x8000000

.PHONY: debug
debug:
# before you start gdb, you must start st-util
	$(GDB) -ex "tar ext :4242" $(PROJECT).elf
