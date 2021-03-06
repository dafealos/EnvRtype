#'@title  Envirotype-informed kernels for statistical models
#'
#' @description Get multiple genomic and/or envirotype-informed kernels for bayesian genomic prediciton.
#' @author Germano Costa Neto
#' @param K_E list. Contains nmatrices of envirotype-related kernels (n x n genotypes-environment). If NULL, benchmarck genomic kernels are built.
#' @param K_G list. Constains matrices of genomic enabled kernels (p x p genotypes). See BGGE::getK for more information.
#' @param Y data.frame. Should contain the following colunms: environemnt, genotype, phenotype.
#' @param model character. Model structure for genomic predicion. It can be \code{c('MM','MDs','E-MM','E-MDs')}, in which MM (main effect model \eqn{Y=fixed + G}) and MDs (\eqn{Y=fixed+G+GxE}).
#' @param reaction boolean. Indicates the inclusion of a reaction norm based GxE kernel (default = FALSE).
#' @param intercept.random boolean. Indicates the inclusion of a genomic random intercept (default = FALSE). For more details, see BGGE package vignette.
#' @param dimension_KE character. \code{size_E=c('q','n')}. In the first, 'k' means taht the environmental relationship kernel has the dimensions of q x q observations,in which q is the number of environments. If 'n', the relationship kernel has the dimension n=pq, in which p is the number of genotypes
#' @param ne numeric. denotes the number of environments (q)
#' @param ng numeric. denotes the number of genotypes (p)
#' @param gid.id character. denotes the name of the column respectively to genotypes
#' @param env.id character. denotes the name of the column respectively to environments
#' @return
#' A list of kernels (relationship matrices) to be used in genomic models.
#'
#' @details
#' TODO Define models.
#'
#' @examples
#' ### Loading the genomic, phenotype and weather data
#' data('maizeG'); data('maizeYield'); data("maizeWTH")
#'
#' ### Y = fixed + G
#' MM <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                  Y = maizeYield, model = 'MM')
#' ### Y = fixed + G + GE
#' MDs <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                   Y = maizeYield, model = 'MDs')
#'
#' ### Enriching models with weather data
#' W.cov <- W_matrix(env.data = maizeWTH)
#' H <- env_kernel(env.data = W.cov, Y = maizeYield,gaussian=TRUE)
#'
#' EMM <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                   Y = maizeYield,K_E = list(W = H$envCov),
#'                   model = 'EMM') # or model = MM
#'
#' ### Y = fixed + G + W + GE
#' EMDs <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                    Y = maizeYield,
#'                    K_E = list(W = H$envCov),
#'                    model = 'MDs') # or model = MDs
#'
#' ### Y = fixed + W + G + GW
#' RN <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                  Y = maizeYield,
#'                  K_E = list(W = H$envCov),
#'                  model = 'RNMM')
#'
#' ### Y = fixed + W + G + GW + GE
#' fullRN <- get_kernel(K_G = list(G = as.matrix(maizeG)),
#'                      Y = maizeYield,
#'                      K_E = list(W = H$envCov),
#'                      model = 'RNMDs')
#'
#' @seealso
#' BGGE::getk W_matrix
#'
#' @importFrom BGGE getK
#' @importFrom stats model.matrix
#'
#' @export

get_kernel <-function(K_E = NULL,                    #' environmental kernel ()
                      K_G,                           #' genotypic kernel (p x p genotypes)
                      Y,                             #' phenotypic dataframe named after env, gid and trait
                      model = NULL,                  #' family model c('MM','MDs','EMM','EMDs','RNMM','RNMDs'),
                      intercept.random = FALSE,      #' insert genomic random intercept)
                      reaction = FALSE,              #' include reaction-norms (see model arguments)
                      dimension_KE = NULL,           #' k environments or n observations (n = pq)
                      ne = NULL,                     #' number of environments (calculated by default)
                      ng = NULL,                     #' number of genotypes (calculated by default)
                      env.id = 'env',
                      gid.id = 'gid'
                      ){
  #----------------------------------------------------------------------------
  # Start Step
  #  Y <- data.frame(env=Y[,env.id],gid=Y[,gen.id],value=Y[,trait.id])
  if (is.null(K_G))   stop('Missing the list of genomic kernels')
  if (!requireNamespace('BGGE')) utils::install.packages("BGGE")
  # if(!any(model %in% c("MM","MDs",'E-MM','E-MDs'))) stop("Model not specified. Choose between MM or MDs")
  if(is.null(model)) model <- 'MM'
  if(model == 'MM'   ){reaction <- FALSE; model_b <- 'MM';K_E=NULL}
  if(model == 'MDs'  ){reaction <- FALSE; model_b <-'MDs';K_E=NULL}
  if(model == 'EMM'  ){reaction <- FALSE; model_b <- 'MM'}
  if(model == 'EMDs' ){reaction <- FALSE; model_b <-'MDs'}
  if(model == 'RNMM' ){reaction <- TRUE; model_b <- 'MM'}
  if(model == 'RNMDs'){reaction <- TRUE; model_b <- 'MDs'}

  #----------------------------------------------------------------------------
  # getting genomic kernels (see BGGE)
  #----------------------------------------------------------------------------
  names(Y)[1:2] = c('env','gid')
  Y <- droplevels(Y)
  K = BGGE::getK(Y = Y, setKernel = K_G, model = model_b,intercept.random = intercept.random);
  names(K)   <- paste0('KG_',names(K))

  if(is.null(ne)) ne = length(unique(Y$env))
  Zg <- stats::model.matrix(~0+gid,Y)
  ng <- length(unique(Y$gid))
  #----------------------------------------------------------------------------
  # If K_E is null, return benchmark genomic model
  #----------------------------------------------------------------------------
  if(is.null(K_E)){
    if(isFALSE(reaction)){
      cat("----------------------------------------------------- \n")
      cat('ATTENTION \n')
      cat('No K_E kernel was provided \n')
      cat('Environment effects assumed as fixed \n')
      cat("----------------------------------------------------- \n")
      cat(paste0('Model: ',model_b,'\n'))
      cat(paste0('Reaction Norm for E effects: ',FALSE,'\n'))
      cat(paste0('Reaction Norm for GxE effects: ',reaction,'\n'))
      cat(paste0('Intercept random: ',intercept.random,'\n'))
      cat(paste0("Kernels used: ",length(K),'\n'))
      cat("----------------------------------------------------- \n")
      return(K)
    }
    return(K)

  }
  #----------------------------------------------------------------------------
  # Envirotype-enriched models (for E effects)
  #----------------------------------------------------------------------------
  if(is.null(dimension_KE)) dimension_KE <- 'q'
  # main envirotype effect

  if(dimension_KE == 'q'){
    K_Em = list()
    for(q in 1:length(K_E)) K_Em[[q]] <- K_E[[q]] %x% matrix(1,ncol=ng,nrow = ng)

    h <- length(K_E);
    n <- length(K);
  }
  if(dimension_KE =='n') K_Em <- K_E

  K_e <- c()
  for(q in 1:h) K_e[[q]] = list(Kernel = K_Em[[q]], Type = "D")
  names(K_e) <- paste0('KE_',names(K_E))


  K_f <- Map(c,c(K,K_e))

  #----------------------------------------------------------------------------
  # Envirotype-enriched models (for GE+E effects)
  #----------------------------------------------------------------------------
  if(isTRUE(reaction)){
    if(dimension_KE == 'n'){
      Ng<-names(K_G)
      for(i in 1:ng) K_G[[i]] <- matrix(1,ncol=ne,nrow=ne) %x% K_G[[i]]#tcrossprod(Zg%*%K_G[[i]])
      ne <- length(K_E)
      A<-c()
      nome<-c()
      Ne = names(K_E)
      ng = length(K_G)
      for(g in 1:ng){for(e in 1:ne) {A <- cbind(A,list(K_G[[g]]*K_E[[e]])); nome <- c(nome,paste0('KGE_',Ng[g],Ne[e]))}}
      K_GE <- c()
      for(ge in 1:length(A)) K_GE[[ge]] <- list(Kernel=A[[ge]],Type='D')
      names(K_GE) <- nome
      K_f <- Map(c,c(K,K_e,K_GE))
    }
    if(dimension_KE == 'k'){
      Ng<-names(K_G)
      #   for(i in 1:ng) K_G[[i]] <- matrix(1,ncol=ne,nrow=ne) %x% K_G[[i]]#tcrossprod(Zg%*%K_G[[i]])
      #  ne <- length(K_E)
      A<-c()
      nome<-c()
      Ne<-names(K_E)
      ne = length(K_E)
      ng = length(K_G)
      for(g in 1:ng){for(e in 1:ne) {A <- cbind(A,list(K_E[[e]]%x%K_G[[g]])); nome <- c(nome,paste0('KGE_',Ng[g],Ne[e]))}}
      K_GE <- c()
      for(ge in 1:length(A)) K_GE[[ge]] <- list(Kernel=A[[ge]],Type='D')
      names(K_GE) <- nome
      K_f <- Map(c,c(K,K_e,K_GE))
    }

  }

  if(isTRUE(intercept.random)) K_f<-K_f[-grep(names(K_f),pattern = 'GE_Gi')]
  #----------------------------------------------------------------------------
  # Reporting status
  #----------------------------------------------------------------------------

  cat("----------------------------------------------------- \n")
  cat(paste0('Model: ',model_b,'\n'))
  cat(paste0('Reaction Norm for E effects: ',TRUE,'\n'))
  cat(paste0('Reaction Norm for GxE effects: ',reaction,'\n'))
  cat(paste0('Intercept random: ',intercept.random,'\n'))
  cat(paste0("Total number of kernels: ",length(K_f),'\n'))
  cat("----------------------------------------------------- \n")
  return(K_f)
}

