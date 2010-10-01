################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/xl-boot.c 

OBJS += \
./src/xl-boot.o 

C_DEPS += \
./src/xl-boot.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -DXLB_LOCBLOB_OFFSET=0xF80000 -Wall -O0 -g3 -c -fmessage-length=0 -I../../tpos_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mno-xl-soft-div -mcpu=v7.30.b -mno-xl-soft-mul -mhard-float -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"  -o $@ $<
	@echo 'Finished building: $<'
	@echo ' '


