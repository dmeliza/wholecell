% MATRIX_CORR Computes the correlation matrix of the input sample matrix
%
%    M = matrix_corr(X)								            
%                                                               
%  INPUT                                                         
%    X - s by n sample matrix					                         
%                                                                    
%  OUTPUT                                                        
%    M = X' * X	  - n by n correlation matrix 												
%				
%  Note: This function is significantly slower than basic Matlab matrix
%        multipication but it uses much less memory.
%
% Neo 05.24.02													 