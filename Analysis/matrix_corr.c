/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*\
||~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~||
||                                                                       ||
||      M = matrix_corr(X)								                 ||
||                                                                       ||
||      INPUT                                                            ||
||			X - m by n matrix					                         || 
||                                                                       ||
||      OUTPUT                                                           ||
||			M = X' * X													 ||
||																		 ||
||																		 ||
||		05.24.02	Neo													 ||
||                                                                       ||
||~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~||
\*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

#include "mex.h"
#include "math.h"

/*-----------------------------------------------------*\
 *       PROTOTYPES                                    *
\*-----------------------------------------------------*/

double dotprod(double *vec1, double *vec2, long n);

/*=====================================================*\
 *       MATLAB GATEWAY ROUTINE FOR VECEST             *
\*=====================================================*/

/* Input Arguments */
#define	X_IN prhs[0]

/* Output Arguments */
#define	M_OUT plhs[0]

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double *Vec1, *Vec2, *X, *M;
  long rows, cols, length, i, j;

  /* Assign Values From Input */	
  length = mxGetM(X_IN);		/* Number or Rows in input */
  rows = mxGetN(X_IN);			/* Number of Rows in output */
  cols = mxGetN(X_IN);			/* Number of Columns in output*/

  /* Check arguments */
  if (nrhs != 1) {
    mexErrMsgTxt("MATRIX_CORR requires ONE input arguments.");
  } else if (nlhs > 1) {
    mexErrMsgTxt("MATRIX_CORR only gives ONE output argument.");
  }

  /* Create matrix for the return arguments */
  M_OUT = mxCreateDoubleMatrix(rows,cols,mxREAL);

  /* Assign pointers to the various parameters */
  X = mxGetPr(X_IN);
  M = mxGetPr(M_OUT);

  /* Calculate matrix multiplication one element at a time */
  /*    Note: Matrix is diagonaly symmetric!               */
  for (i=0; i<rows; i++) {
	for (j=0; j<cols; j++) {
	  Vec1 = X + (i * length);
	  Vec2 = X + (j * length);
	  if (i > j) {
		M[i + (j * rows)] = M[j + (i * rows)];	/* Element has already been calculated */
	  } else {
		M[i + (j * rows)] = dotprod(Vec1,Vec2,length);
	  }
	}
  }

  return;
}

/*-----------------------------------------------------*\
 *       SUBROUTINES                                   *
\*-----------------------------------------------------*/

double dotprod(double *vec1, double *vec2, long n)
{
  /* Dot Product Function */

  double sum;
  long i;

  sum = 0.0;
  for (i=0; i<n; i++) {
    sum += *vec1 * *vec2;
    vec1 += 1;
	vec2 += 1;
  }
  
  return sum;
}