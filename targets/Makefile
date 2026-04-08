all: patient_zero patient_zero_waits

patient_zero: patient_zero.c
	gcc -O0 -fno-inline -o patient_zero patient_zero.c -no-pie

patient_zero_waits: patient_zero_waits.c
	gcc -O0 -fno-inline -o patient_zero_waits patient_zero_waits.c -no-pie

clean:
	rm -f patient_zero patient_zero_waits
