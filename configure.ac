#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([FULL-PACKAGE-NAME], [VERSION], [BUG-REPORT-ADDRESS])

# Checks for programs.
AC_PROG_AWK
AC_PATH_PROG([GFORTRAN_DIR],[gfortran])
AC_SUBST([GFORTRAN_DIR])

AC_ARG_VAR([NETCDF_DIR],[Directory where netcdf is installed])
AC_SUBST([NETCDF_DIR])

LDFLAGS_BACKUP=${LDFLAGS}
if test -z "${NETCDF_DIR}"; then
    LDFLAGS="${LDFLAGS}"
else
    LDFLAGS="-L${NETCDF_DIR}/lib ${LDFLAGS}"
fi

#Check for /usr/local/ Directory
AC_CHECK_FILE([/usr/local],[OTHERLIBS="-L/usr/local/lib"; OTHERINC="-I/usr/local/include";])
AC_SUBST([OTHERLIBS])
AC_SUBST([OTHERINC])

# Checks for libraries.
FOUND_ECCODES=0
FOUND_ECCODES_F90=0
# FIXME: Replace `main' with a function in `-leccodes':
AC_CHECK_LIB([eccodes], [main],[FOUND_ECCODES=1])
# FIXME: Replace `main' with a function in `-leccodes_f90':
AC_CHECK_LIB([eccodes_f90], [main],[FOUND_ECCODES_F90=1])

if test $FOUND_ECCODES -eq 1 -a $FOUND_ECCODES_F90 -eq 1; then
    USEGRIB='T'
else
    USEGRIB='F'
fi
AC_SUBST([USEGRIB])

# FIXME: Replace `main' with a function in `-lhourssince':
AC_CHECK_LIB([hourssince], [main],[],[AC_MSG_ERROR([Required library "hourssince" not found])])

FOUND_NETCDF=0
FOUND_NETCDFF=0
# FIXME: Replace `main' with a function in `-lnetcdf':
AC_CHECK_LIB([netcdf], [main],[FOUND_NETCDF=1])
# FIXME: Replace `main' with a function in `-lnetcdff':
AC_CHECK_LIB([netcdff], [main],[FOUND_NETCDFF=1])

if test $FOUND_NETCDF -eq 1 -a $FOUND_NETCDFF -eq 1; then
    USENETCDF='T'
else
    USENETCDF='F'
fi
AC_SUBST([USENETCDF])

if test $USENETCDF = 'F' -a $USEGRIB = 'F'; then
    AC_MSG_ERROR([Need one of either Net cdf or GRIB libraries]);
fi

# FIXME: Replace `main' with a function in `-lprojection':
AC_CHECK_LIB([projection], [main],[],[AC_MSG_ERROR([Required library "projection" not found])])

LDFLAGS=${LDFLAGS_BACKUP}

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([makefile])
AC_OUTPUT
