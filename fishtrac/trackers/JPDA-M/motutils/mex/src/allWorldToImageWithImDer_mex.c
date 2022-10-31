/***************************************************************************
 *   cameraModel.cpp   - description
 *
 *   This program is part of the Etiseo project.
 *
 *   See http://www.etiseo.net  http://www.silogic.fr
 *
 *   (C) Silogic - Etiseo Consortium
 ***************************************************************************/

#include "mex.h"
#include <math.h>

void undistortedToDistortedSensorCoord(double Xu, double Yu, double *Xd, double *Yd, double mKappa1) {
    double Ru;
    double Rd;
    double lambda;
    double c;
    double d;
    double Q;
    double R;
    double D;
    double S;
    double T;
    double sinT;
    double cosT;
    
    if (((Xu == 0) && (Yu == 0)) || (mKappa1 == 0)) {
        *Xd = Xu;
        *Yd = Yu;
    }
    else {
        Ru = sqrt(Xu*Xu + Yu*Yu);
        
        c = 1.0 / mKappa1;
        d = -c * Ru;
        
        Q = c / 3;
        R = -d / 2;
        D = Q*Q*Q + R*R;
        
        if (D >= 0) {
            /* one real root */
            D = sqrt(D);
            if (R + D > 0) {
                S = pow(R + D, 1.0/3.0);
            }
            else {
                S = -pow(-R - D, 1.0/3.0);
            }
            
            if (R - D > 0) {
                T = pow(R - D, 1.0/3.0);
            }
            else {
                T = -pow(D - R, 1.0/3.0);
            }
            
            Rd = S + T;
            
            if (Rd < 0) {
                Rd = sqrt(-1.0 / (3 * mKappa1));
                /*fprintf (stderr, "\nWarning: undistorted image point to distorted image point mapping limited by\n");
                 * fprintf (stderr, "         maximum barrel distortion radius of %lf\n", Rd);
                 * fprintf (stderr, "         (Xu = %lf, Yu = %lf) -> (Xd = %lf, Yd = %lf)\n\n", Xu, Yu, Xu * Rd / Ru, Yu * Rd / Ru);*/
            }
        }
        else {
            /* three real roots */
            D = sqrt(-D);
            S = pow( sqrt(R*R + D*D) , 1.0/3.0 );
            T = atan2(D, R) / 3;
            sinT = sin(T);
            cosT = cos(T);
            
            /* the larger positive root is    2*S*cos(T)                   */
            /* the smaller positive root is   -S*cos(T) + SQRT(3)*S*sin(T) */
            /* the negative root is           -S*cos(T) - SQRT(3)*S*sin(T) */
            
            Rd = -S * cosT + sqrt(3.0) * S * sinT;	/* use the smaller positive root */
        }
        
        lambda = Rd / Ru;
        
        Xd[0] = Xu * lambda;
        Yd[0] = Yu * lambda;
    }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    
    /* /Declarations */
    const mxArray *Dpxdata, *Dpydata, *Sxdata, *Cxdata, *Cydata, *Xwdata, *Ywdata, *Zwdata, *focaldata, *kappadata, \
            *mRdata, *mTdata;
    
    double mDpx, mDpy, mSx, *Xw, *Yw, *Zw, focal, kappa, \
            mR11, mR12, mR13, mR21, mR22, mR23, mR31, mR32, mR33, \
            mTx, mTy, mTz, mCx, mCy;
    
    double xc;
    double yc;
    double zc;
    double Xu;
    double Yu;
    double Xd[1];
    double Yd[1];
    double xw, yw, zw;
    int F, N;
    
    double *Xi, *Yi, *imDer;
    int i, j, ind;
    
    double row1, row2, row3;
    double row1sq, row2sq, row3sq, row3cu, r1dr3, r2dr3, r1sqdr3sq, r2sqdr3sq, r1dr3sq, r2dr3sq;
    double fsq, twofsq, ksq, kcu, ksqfourth, kcu27th, fsqr1r3sq, fsqr2r3sq, sqrtfr1r2, sqrtterm1;
    double sqrtfr1r2div2divk, longterm1, SxfdivDpx, sqrtsumcubed, sqrtdiffcubed, sqrtsumcubeddiv3, fghj, lmno;
    
    double f;
    double k;
    double Dpx;
    double Dpy;
    double Sx;
    
    double *mR, *mT;
    int dims[4]; 
    
    /* //Copy input pointer x */
    Xwdata = prhs[0];
    Ywdata = prhs[1];
    Zwdata = prhs[2];
    Dpxdata = prhs[3];
    Dpydata = prhs[4];
    Sxdata = prhs[5];
    Cxdata = prhs[6];
    Cydata = prhs[7];
    focaldata = prhs[8];
    kappadata = prhs[9];
    mRdata = prhs[10];
    mTdata = prhs[11];
    
    mDpx = (double)(mxGetScalar(Dpxdata));
    mDpy = (double)(mxGetScalar(Dpydata));
    mSx = (double)(mxGetScalar(Sxdata));
    Xw = mxGetPr(Xwdata);
    Yw = mxGetPr(Ywdata);
    Zw = mxGetPr(Zwdata);
    focal = (double)(mxGetScalar(focaldata));
    kappa = (double)(mxGetScalar(kappadata));
    mCx = (double)(mxGetScalar(Cxdata));
    mCy = (double)(mxGetScalar(Cydata));
    
    f=focal;
    k=kappa;
    Dpx=mDpx;
    Dpy=mDpy;
    Sx=mSx;

    mR = mxGetPr(mRdata);
    mT = mxGetPr(mTdata);
    
    mR11 = mR[0];
    mR12 = mR[3];
    mR13 = mR[6];
    mR21 = mR[1];
    mR22 = mR[4];
    mR23 = mR[7];
    mR31 = mR[2];
    mR32 = mR[5];
    mR33 = mR[8];
    mTx = mT[0];
    mTy = mT[1];
    mTz = mT[2];
    
    /* //Get number of frames and targets */
    F = mxGetN(Xwdata);
    N = mxGetM(Xwdata);
    
    
    /* Allocate memory and assign output pointer */
    plhs[0] = mxCreateDoubleMatrix(N, F, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(N, F, mxREAL);
    dims[0]=2; dims[1]=2; dims[2]=N; dims[3]=F;
    
    plhs[2] = mxCreateNumericArray((mwSize)4, dims, mxDOUBLE_CLASS, mxREAL);
    
    /*//Get a pointer to the data space in our newly allocated memory */
    Xi = mxGetPr(plhs[0]);
    Yi = mxGetPr(plhs[1]);
    imDer = mxGetPr(plhs[2]);
    
    /* */
    for(i=0;i<F;i++) {
        for(j=0;j<N;j++) {
            ind=(i*N)+j;
            if (Xw[ind] != 0){
                xw=Xw[ind];yw=Yw[ind];zw=Zw[ind];
                /* convert from world coordinates to camera coordinates */
                xc = mR11 * xw + mR12 * yw + mR13 * zw + mTx;
                yc = mR21 * xw + mR22 * yw + mR23 * zw + mTy;
                zc = mR31 * xw + mR32 * yw + mR33 * zw + mTz;
                
                /* convert from camera coordinates to undistorted sensor plane coordinates */
                Xu = focal * xc / zc;
                Yu = focal * yc / zc;
                
                /* convert from undistorted to distorted sensor plane coordinates */
                undistortedToDistortedSensorCoord(Xu, Yu, Xd, Yd, kappa);
                
                /* convert from distorted sensor plane coordinates to image coordinates */
                Xi[ind] = Xd[0] * mSx / mDpx + mCx;
                Yi[ind] = Yd[0] / mDpy + mCy;
                
                /* image Derivatives */
                
                row1=xc;
                row2=yc;
                row3=zc;
                
                row1sq=row1*row1;
                row2sq=row2*row2;
                row3sq=row3*row3;
                row3cu=row3sq*row3;
                r1dr3=row1/row3;
                r2dr3=row2/row3;
                r1sqdr3sq=row1sq/row3sq;
                r2sqdr3sq=row2sq/row3sq;
                r1dr3sq=row1/row3sq;
                r2dr3sq=row2/row3sq;
  /*              mexPrintf("A %f %f %f\n",row1,row2,row3);
                mexPrintf("B %f %f %f %f\n",row1sq,row2sq,row3sq,row3cu);
                mexPrintf("C %f %f %f %f %f %f\n",r1dr3,r2dr3,r1sqdr3sq,r2sqdr3sq,r1dr3sq,r2dr3sq); */
                
                fsq=f*f;
                twofsq=2*fsq;
                ksq=k*k;
                kcu=ksq*k;
                ksqfourth=1./4./ksq;
                kcu27th=1./27./kcu;
                fsqr1r3sq=fsq*r1sqdr3sq;
                fsqr2r3sq=fsq*r2sqdr3sq;
                sqrtfr1r2=sqrt(fsqr1r3sq + fsqr2r3sq);
                sqrtterm1=sqrt(ksqfourth*(fsqr1r3sq + fsqr2r3sq) + kcu27th);
                sqrtfr1r2div2divk=1/2./k*sqrtfr1r2;
                longterm1=(pow(sqrtterm1 - sqrtfr1r2div2divk,(1/3.)) - pow(sqrtterm1 + sqrtfr1r2div2divk,(1/3.)));
                SxfdivDpx=1/Dpx*Sx*f;
                sqrtsumcubed=pow(fsqr1r3sq + fsqr2r3sq,(3/2.));
                sqrtdiffcubed=pow(sqrtterm1 - sqrtfr1r2div2divk,(2/3.));
                sqrtsumcubeddiv3=1/3./pow(sqrtterm1 + sqrtfr1r2div2divk,(2/3.));
                fghj=twofsq*mR11*r1dr3sq + twofsq*mR21*r2dr3sq - twofsq*mR31*row1sq/row3cu - twofsq*mR31*row2sq/row3cu;
                lmno=twofsq*mR12*r1dr3sq + twofsq*mR22*r2dr3sq - twofsq*mR32*row1sq/row3cu - twofsq*mR32*row2sq/row3cu;
/*
                mexPrintf("D %f %f %f %f %f %f\n",fsq,twofsq,ksq,kcu,ksqfourth,kcu27th);
                mexPrintf("E %f %f %f %f %f %f\n",fsqr1r3sq,fsqr2r3sq,sqrtfr1r2,sqrtterm1,sqrtfr1r2div2divk,longterm1);
                mexPrintf("F %f %f %f %f %f\n",SxfdivDpx,sqrtsumcubed,sqrtsumcubeddiv3,fghj,lmno);
                */
                

                imDer[0+ind*4]=SxfdivDpx*mR31/sqrtfr1r2*longterm1*r1dr3sq - SxfdivDpx*mR11/sqrtfr1r2*longterm1/row3 - SxfdivDpx/sqrtfr1r2*(1/3./sqrtdiffcubed*(1/8./ksq/sqrtterm1*(fghj) - 1/4./k/sqrtfr1r2*(fghj)) - sqrtsumcubeddiv3*(1/8./ksq/sqrtterm1*(fghj) + 1/4./k/sqrtfr1r2*(fghj)))*r1dr3 + 1/2./Dpx*Sx*f/sqrtsumcubed*longterm1*(fghj)*r1dr3;
                imDer[2+ind*4]=1/2./Dpy*f/sqrtsumcubed*longterm1*(fghj)*r2dr3 - 1/Dpy*f*mR21/sqrtfr1r2*longterm1/row3 - 1/Dpy*f/sqrtfr1r2*(1/3./sqrtdiffcubed*(1/8./ksq/sqrtterm1*(fghj) - 1/4./k/sqrtfr1r2*(fghj)) - sqrtsumcubeddiv3*(1/8./ksq/sqrtterm1*(fghj) + 1/4./k/sqrtfr1r2*(fghj)))*r2dr3 + 1/Dpy*f*mR31/sqrtfr1r2*longterm1*r2dr3sq;
                imDer[1+ind*4]=SxfdivDpx*mR32/sqrtfr1r2*longterm1*r1dr3sq - SxfdivDpx*mR12/sqrtfr1r2*longterm1/row3 - SxfdivDpx/sqrtfr1r2*(1/3./sqrtdiffcubed*(1/8./ksq/sqrtterm1*(lmno) - 1/4./k/sqrtfr1r2*(lmno)) - sqrtsumcubeddiv3*(1/8./ksq/sqrtterm1*(lmno) + 1/4./k/sqrtfr1r2*(lmno)))*r1dr3 + 1/2./Dpx*Sx*f/sqrtsumcubed*longterm1*(lmno)*r1dr3;
                imDer[3+ind*4]=1/2./Dpy*f/sqrtsumcubed*longterm1*(lmno)*r2dr3 - 1/Dpy*f*mR22/sqrtfr1r2*longterm1/row3 - 1/Dpy*f/sqrtfr1r2*(1/3./sqrtdiffcubed*(1/8./ksq/sqrtterm1*(lmno) - 1/4./k/sqrtfr1r2*(lmno)) - sqrtsumcubeddiv3*(1/8./ksq/sqrtterm1*(lmno) + 1/4./k/sqrtfr1r2*(lmno)))*r2dr3 + 1/Dpy*f*mR32/sqrtfr1r2*longterm1*r2dr3sq;
/*                mexPrintf("%i %f %f %f %f\n",0+ind*4,imDer[0+ind*4],imDer[2+ind*4],imDer[1+ind*4],imDer[3+ind*4]); */
            }
            
        }
    }
    
    return;
}