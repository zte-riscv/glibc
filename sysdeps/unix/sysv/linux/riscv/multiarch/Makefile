ifeq ($(subdir),string)
sysdep_routines += \
  memset \
  memset-generic \
  memset_vector \
  memcpy \
  memcpy-generic \
  memcpy_noalignment \
  memcpy_vector \
  memchr \
  memchr-generic \
  memchr_vector \
  memrchr \
  memrchr-generic \
  memrchr_vector \
  rawmemchr \
  rawmemchr_vector \
  memmove \
  memmove-generic \
  memmove_vector \
  memcmp \
  memcmp-generic \
  memcmp_vector \
  strlen \
  strlen-generic \
  strlen_vector 
  # sysdep_routines

CFLAGS-memcpy_noalignment.c += -mno-strict-align

endif
