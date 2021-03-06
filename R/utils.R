#' @export
getG<-function(x,nChunks=3,scaleCol=TRUE,scaleG=TRUE,verbose=TRUE,i=1:nrow(x),j=1:ncol(x),minVar=1e-5){
    ###
    # Computes a genomic relationship matrix G=XX'
    # Offers options for centering and scaling G=WW' where W=scale(X,center=centerCol,scale=scaleCol)
    # And of scaling the final output so that the average diagonal value is equal to one (scaleG=TRUE)
    # If scaleCol=centerCol=scaleG=FALSE it behaves as tcrossprod(X)
    # Arguments:
    #   x: matrix, ff_matrix, rDMatrix or cDMatrix
    #   nChunks: the number of columns that are processed at a time.
    #   scaleCol, centerCol: TRUE/FALSE whether columns must be centered and scaled before computing XX'
    #   i,j: (integer, boolean or character) indicating which columsn and which rows should be used.
    #        By default all columns and rows are used.
    #  Genomic relationship matrix
    # Value: G=XX'
    ###
    
    nX<-nrow(x);       pX<-ncol(x)
    n<-length(i); 	p<-length(j)
    
    if(n>nX|p>pX){ stop('Index out of bounds')}
    
    if(is.numeric(i)){ if( (min(i)<1)|(max(i)>nX)){ stop('Index out of bounds') }}
    if(is.numeric(j)){ if( (min(j)<1)|(max(j)>pX)){ stop('Index out of bounds') }}
    
    tmp<-x[i,1:2]
    n<-nrow(tmp)
    
    G<-matrix(0,nrow=n,ncol=n)
    rownames(G)<-rownames(tmp)
    colnames(G)<-rownames(G)
    
    end<-0;
    delta<-ceiling(p/nChunks);
    
    for(k in 1:nChunks){
        ini<-end+1;
        end<-min(p,end+delta-1)
        if(verbose){
            cat("Submatrix: ",k," (out of",nChunks,")\n");
            cat("  =>Acquiring genotypes...\n")
        }
        
        # subset
        tmp<-j[ini:end]
        X=x[i,tmp,drop=FALSE];
        
        if(scaleCol){
            VAR<-apply(X=X,FUN=var,MARGIN=2,na.rm=TRUE)
            tmp<-which(VAR<minVar)
            if(length(tmp)>0){
                X<-X[,-tmp]
                VAR<-VAR[-tmp]
            }
        }
        
        if(ncol(X)>0){
            if(verbose){ cat("  =>Computing...\n") }
            if(scaleCol){
                X<-scale(X,center=TRUE,scale=scaleCol)
            }
            TMP<-is.na(X)
            if(any(TMP)){    X<-ifelse(TMP,0,X) }
            G<-G+tcrossprod(X)
        }
    }
    if(scaleG){
        tmp<-mean(diag(G))
        G<-G/tmp
    }
    return(G)
}


#' @export
simPED<-function(filename,n,p,genoChars=1:4,na.string=0,propNA=.02,returnGenos=FALSE){
    if(file.exists(filename)){
        stop(paste('File',filename,'already exists. Please move it or pick a different name.'))
    }
    markerNames<-paste0('mrk_',1:p)
    subjectNames<-paste0('id_',1:n)
    if(returnGenos){
        OUT<-matrix(nrow=n,ncol=p,NA)
        colnames(OUT)<-markerNames
        rownames(OUT)<-subjectNames
    }
    fileOut<-file(filename,open='w')
    pedP<-6+p
    header<-c(c('FID','IID','PAT','MAT','SEX','PHENOTYPE'),markerNames)
    write(header,ncol=pedP,append=TRUE,file=fileOut)
    for(i in 1:n){
        geno<-sample(genoChars,size=p,replace=TRUE)
        geno[runif(p)<propNA]<-na.string
        pheno<-c(0,subjectNames[i],rep(NA,4))
        x<-c(pheno,geno)
        write(x,ncol=pedP,append=TRUE,file=fileOut)
        if(returnGenos){
            OUT[i,]<-geno
        }
    }
    close(fileOut)
    if(returnGenos){
        return(OUT)
    }
}


randomString<-function(){
    paste(sample(c(0:9,letters,LETTERS),size=5,replace=TRUE),collapse="")
}
