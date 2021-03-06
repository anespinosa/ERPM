######################################################################
## Simulation and estimation of Exponential Random Partition Models ## 
## Functions used to run the phase 1 of the estimation algorithm    ##
## Author: Marion Hoffman                                           ##
######################################################################

# Phase 1 wrapper for single observation
run_phase1_single <- function(partition,
                       startingestimates, 
                       z.obs, 
                       nodes, 
                       effects, 
                       objects, 
                       burnin, 
                       thining,
                       gainfactor,
                       a.scaling,
                       r.truncation.p1,
                       mini.steps, 
                       length.p1, 
                       neighborhood,
                       fixed.estimates,
                       sizes.allowed,
                       sizes.simulated,
                       parallel = T,
                       cpus = 1) {
  
  num.nodes <- nrow(nodes)
  num.effects <- length(effects$names)
  
  # find a good starting point
  #first.partition <- find_startingpoint_single(nodes, sizes.allowed)
  first.partition <- partition
  
  # simulate the statisticis distribution
  if(parallel){
    
    sfExport("startingestimates", "first.partition", "nodes", "effects", "objects", "burnin", "thining", "length.p1", "cpus", "mini.steps", "neighborhood", "sizes.allowed", "sizes.simulated")
    res <- sfLapply(1:cpus, fun = function(k) {
      set.seed(k)
      subres <- draw_Metropolis_single(startingestimates, first.partition, nodes, effects, objects, burnin, thining, ceiling(length.p1/cpus), mini.steps, neighborhood, sizes.allowed, sizes.simulated)
      return(subres)
    }
    )
    all.z <- c()
    for(k in 1:cpus) all.z <- rbind(all.z,res[[k]]$draws)
    length.p1 <- cpus * ceiling(length.p1/cpus)
    results.phase1 <- list("draws" = all.z, "last.partition" = res[[cpus]]$last.partition, "all.partitions" = NULL) 
    
  }else{
    
    results.phase1 <- draw_Metropolis_single(startingestimates, first.partition, nodes, effects, objects, burnin, thining, length.p1, mini.steps, neighborhood, sizes.allowed, sizes.simulated)
  }
  z.phase1 <- results.phase1$draws
  
  # calculate autocorrelation to check afterhand
  autocors <- rep(0,num.effects)
  for(e in 1:num.effects){
    autocors[e] <- cor(results.phase1$draws[1:(length.p1-1),e],results.phase1$draws[2:length.p1,e])
  }
  print("Autocorrelations in phase 1:")
  print(autocors)
  
  # calculate the covariance and scaling matrices
  inverted_matrices <- calculate_inverted_covariance_and_scaling(startingestimates, 
                                                        z.obs, 
                                                        nodes, 
                                                        effects, 
                                                        objects, 
                                                        a.scaling,
                                                        length.phase = length.p1, 
                                                        z.phase = z.phase1,
                                                        fixed.estimates)
  inv.zcov <- inverted_matrices$inv.zcov
  inv.scaling <- inverted_matrices$inv.scaling
  
  # Phase 1 procedure
  estimates.phase1 <- phase1(startingestimates,
                     inv.zcov,
                     inv.scaling,
                     z.phase1,
                     z.obs, 
                     nodes, 
                     effects, 
                     objects, 
                     r.truncation.p1,
                     length.p1, 
                     fixed.estimates)
  
  return( list("estimates" = estimates.phase1, 
               "inv.zcov" = inv.zcov,
               "inv.scaling" = inv.scaling,
               "autocorrelations" = autocors) )
  
}


# Phase 1 wrapper for multiple observations
run_phase1_multiple <- function(partitions,
                              startingestimates, 
                              z.obs, 
                              presence.tables, 
                              nodes, 
                              effects, 
                              objects, 
                              burnin, 
                              thining,
                              gainfactor,
                              a.scaling,
                              r.truncation.p1,
                              mini.steps, 
                              length.p1, 
                              neighborhood,
                              fixed.estimates,
                              sizes.allowed,
                              sizes.simulated,
                              parallel = F,
                              cpus = 1) {
  
  num.nodes <- nrow(nodes)
  num.effects <- length(effects$names)
  num.obs <- ncol(presence.tables)
  
  # find good starting pointS
  #first.partitions <- find_startingpoint_multiple(presence.tables,nodes,sizes.allowed)
  first.partitions <- partitions
  
  # simulate the statisticis distribution
  if(parallel){
    
    sfExport("startingestimates", "first.partitions", "presence.tables", "nodes", "effects", "objects", "burnin", "thining", "length.p1", "cpus", "mini.steps", "neighborhood", "sizes.allowed", "sizes.simulated")
    res <- sfLapply(1:cpus, fun = function(k) {
      set.seed(k)
      subres <- draw_Metropolis_multiple(startingestimates, first.partitions, presence.tables, nodes, effects, objects, burnin, thining, ceiling(length.p1/cpus), mini.steps, neighborhood, sizes.allowed, sizes.simulated)
      return(subres)
    }
    )
    all.z <- c()
    for(k in 1:cpus) all.z <- rbind(all.z,res[[k]]$draws)
    length.p1 <- cpus * ceiling(length.p1/cpus)
    results.phase1 <- list("draws" = all.z, "last.partitions" = res[[cpus]]$last.partitions, "all.partitions" = NULL) 
    
  }else{
    
    results.phase1 <- draw_Metropolis_multiple(startingestimates, first.partitions, presence.tables, nodes, effects, objects, burnin, thining, length.p1, mini.steps, neighborhood, sizes.allowed, sizes.simulated)
    
  }
  z.phase1 <- results.phase1$draws
  
  # calculate autocorrelation to check afterhand
  autocors <- rep(0,num.effects)
  for(e in 1:num.effects){
    autocors[e] <- cor(results.phase1$draws[1:(length.p1-1),e],results.phase1$draws[2:length.p1,e])
  }
  print("Autocorrelations in phase 1:")
  print(autocors)
  
  # calculate the covariance and scaling matrices
  inverted_matrices <- calculate_inverted_covariance_and_scaling(startingestimates, 
                                                                 z.obs, 
                                                                 nodes, 
                                                                 effects, 
                                                                 objects, 
                                                                 a.scaling,
                                                                 length.phase = length.p1, 
                                                                 z.phase = z.phase1,
                                                                 fixed.estimates)
  inv.zcov <- inverted_matrices$inv.zcov
  inv.scaling <- inverted_matrices$inv.scaling
  
  # Phase 1 procedure
  estimates.phase1 <- phase1(startingestimates,
                             inv.zcov,
                             inv.scaling,
                             z.phase1,
                             z.obs, 
                             nodes, 
                             effects, 
                             objects, 
                             r.truncation.p1,
                             length.p1, 
                             fixed.estimates)
  
  return( list("estimates" = estimates.phase1, 
               "inv.zcov" = inv.zcov,
               "inv.scaling" = inv.scaling,
               "autocorrelations" = autocors) )
  
}


# Core functions of phase 1
phase1 <- function(startingestimates,
                   inv.zcov,
                   inv.scaling,
                   z.phase1,
                   z.obs, 
                   nodes, 
                   effects, 
                   objects, 
                   r.truncation.p1,
                   length.p1, 
                   fixed.estimates) {
  
  num.nodes <- nrow(nodes)
  num.effects <- length(effects$names)
  
  # normal procedure ( no fixed estimates)
  if(is.null(fixed.estimates)){
    
    
    # compute a first rough estimate of statistics by averaging all results of phase
    z.mean <- rep(0, num.effects)
    for(i in 1:length.p1) {
      z.mean <- z.mean + z.phase1[i,]
    }
    z.mean <- z.mean / length.p1
    
    
    # compute truncating factor
    r <- 1
    diff <- (z.mean - z.obs)
    maxratio <-  max(sqrt((t(diff) %*% inv.zcov %*% diff / num.effects)))
    if(maxratio > r.truncation.p1) {
      r <- r.truncation.p1 / maxratio
    }
    
    # compute new estimates
    print(r)
    print(inv.scaling)
    print(z.mean)
    print(z.obs)
    estimates.phase1 <- startingestimates - r*inv.scaling%*%(z.mean - z.obs)
    
    
    # fixed parameters procedure
  } else {
    
    # find the indexes to remove from the estimation
    fixed.indexes <- c()
    unfixed.indexes <- c()
    for(e in 1:num.effects){
      if(!is.null(fixed.estimates[[e]])) 
        fixed.indexes <- c(fixed.indexes,e)
      else
        unfixed.indexes <- c(unfixed.indexes,e)
    }
    
    # compute a first rough estimate of statistics by averaging all results of phase 1
    z.mean <- rep(0, length(unfixed.indexes))
    for(i in 1:length.p1) {
      z.mean <- z.mean + z.phase1[i,unfixed.indexes]
    }
    z.mean <- z.mean / length.phase1
    
    # compute truncating factor
    r <- 1
    diff <- (z.mean - z.obs[unfixed.indexes])
    maxratio <-  max(sqrt((t(diff) %*% inv.zcov %*% diff / length(unfixed.indexes))))
    if(maxratio > r.truncation.p1) {
      r <- r.truncation.p1 / maxratio
    }
    
    # compute new estimates
    estimates.phase1 <- startingestimates
    estimates.phase1[unfixed.indexes] <- estimates.phase1[unfixed.indexes] - r*inv.scaling%*%(z.mean - z.obs[unfixed.indexes])
    
  }
  
  print("Estimated statistics after phase 1")
  print(z.mean)
  print("Estimates after phase 1")
  print(estimates.phase1)
  
  return(estimates.phase1)
  
}


calculate_inverted_covariance_and_scaling <- function(startingestimates, 
                                                      z.obs, 
                                                      nodes, 
                                                      effects, 
                                                      objects, 
                                                      a.scaling,
                                                      length.phase, 
                                                      z.phase,
                                                      fixed.estimates){
  
  num.nodes <- nrow(nodes)
  num.effects <- length(effects$names)
  
  
  # normal procedure ( no fixed estimates)
  if(is.null(fixed.estimates)){
    
    # compute a first rough estimate of statistics by averaging all results of phase
    z.mean <- rep(0, num.effects)
    for(i in 1:length.phase) {
      z.mean <- z.mean + z.phase[i,]
    }
    z.mean <- z.mean / length.phase
    
    # compute the covariance matrix of all results
    z.cov <- matrix(0, nrow=num.effects, ncol=num.effects)
    for(i in 1:length.phase) {
      z.cov <- z.cov + z.phase[i,]%*%t(z.phase[i,])
    }
    z.cov <- z.cov / length.phase
    z.cov <- z.cov - z.mean %*% t(z.mean)
    inv.zcov <- solve(z.cov)
    
    # compute scaling matrix
    scaling <- z.cov
    
    scaling[ row(scaling) != col(scaling) ] <- a.scaling * scaling[ row(scaling) != col(scaling) ]
    inv.scaling <- solve(scaling)

    
    # fixed parameters procedure
  } else {
    
    # find the indexes to remove from the estimation
    fixed.indexes <- c()
    unfixed.indexes <- c()
    for(e in 1:num.effects){
      if(!is.null(fixed.estimates[[e]])) 
        fixed.indexes <- c(fixed.indexes,e)
      else
        unfixed.indexes <- c(unfixed.indexes,e)
    }
    
    # compute a first rough estimate of statistics by averaging all results of phase 1
    z.mean <- rep(0, length(unfixed.indexes))
    for(i in 1:length.phase) {
      z.mean <- z.mean + z.phase[i,unfixed.indexes]
    }
    z.mean <- z.mean / length.phase
    
    # compute the covariance matrix of all results
    z.cov <- matrix(0, nrow=length(unfixed.indexes), 
                    ncol=length(unfixed.indexes))
    for(i in 1:length.phase) {
      z.cov <- z.cov + z.phase[i,length(unfixed.indexes)]%*%t(z.phase[i,length(unfixed.indexes)])
    }
    z.cov <- z.cov / length.phase
    z.cov <- z.cov - z.mean %*% t(z.mean)
    inv.zcov <- solve(z.cov)
    
    # compute scaling matrix
    scaling <- z.cov
    
    # # handle extreme cases
    # if(det(as.matrix(z.cov)) == 0){
    #   z.cov[ row(z.cov) == col(z.cov) ] <- 0.1
    #   scaling[ row(scaling) == col(scaling) ] <- 0.1
    # }
    
    scaling[ row(scaling) != col(scaling) ] <- a.scaling * scaling[ row(scaling) != col(scaling) ]
    inv.scaling <- solve(scaling)

    
  }
  
  return(list(inv.zcov = inv.zcov,
              inv.scaling = inv.scaling))
}




