function initialize!(integrator,cache::AB3ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::AB3ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2, k3 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 2
    cache.step += 1
    ttmp = t + (2/3)*dt
    ralk2 = f(uprev + (2/3)*dt*k1, p, ttmp)       #Ralston Method
    u = uprev + (dt/4)*(k1 + 3*ralk2)
    if cnt == 1
      k3 = k1
    else
      k2 = k1
    end
  else
    u  = uprev + (dt/12)*(23*k1 - 16*k2 + 5*k3)
    k3 = k2
    k2 = k1
  end
  cache.k2 = k2
  cache.k3 = k3
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::AB3Cache)
  @unpack tmp,fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::AB3Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,ralk2,k = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 2
    cache.step += 1
    ttmp = t + (2/3)*dt
    @. tmp = uprev + (2/3)*dt*k1
    f(ralk2, tmp, p, ttmp)
    @. u = uprev + (dt/4)*(k1 + 3*ralk2)        #Ralston Method
    if cnt == 1
      cache.k3 .= k1
    else
      cache.k2 .= k1
    end
  else
    @. u  = uprev + (dt/12)*(23*k1 - 16*k2 + 5*k3)
    cache.k2,cache.k3 = k3,k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

function initialize!(integrator,cache::ABM32ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::ABM32ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2,k3 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step == 1
    cache.step += 1
    ttmp = t + (2/3)*dt
    ralk2 = f(uprev + (2/3)*dt*k1, p, ttmp)     #Ralston Method
    u = uprev + (dt/4)*(k1 + 3*ralk2)
    k2 = k1
  else
    perform_step!(integrator, AB3ConstantCache(k2,k3,cnt))
    k = integrator.fsallast
    u = uprev + (dt/12)*(5*k + 8*k1 - k2)
    k3 = k2
    k2 = k1
  end
  cache.k2 = k2
  cache.k3 = k3
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::ABM32Cache)
  @unpack fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::ABM32Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,ralk2,k = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step == 1
    cache.step += 1
    ttmp = t + (2/3)*dt
    @. tmp = uprev + (2/3)*dt*k1
    f(ralk2, tmp, p, ttmp)
    @. u = uprev + (dt/4)*(k1 + 3*ralk2)       #Ralston Method
    cache.k2 .= k1
  else
    if cnt == 2
      perform_step!(integrator, AB3Cache(u,uprev,fsalfirst,copy(k2),k3,ralk2,k,tmp,cnt))  #Here passing copy of k2, otherwise it will change in AB3()
    else
      perform_step!(integrator, AB3Cache(u,uprev,fsalfirst,k2,k3,ralk2,k,tmp,cnt))
    end
    k = integrator.fsallast
    @. u = uprev + (dt/12)*(5*k + 8*k1 - k2)
    cache.k2,cache.k3 = k3,k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

function initialize!(integrator,cache::AB4ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::AB4ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2,k3,k4 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 3
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    k2 = f(uprev + halfdt*k1, p, ttmp)
    k3 = f(uprev + halfdt*k2, p, ttmp)
    k4 = f(uprev + dt*k3, p, t+dt)
    u = uprev + (dt/6)*(2*(k2 + k3) + (k1+k4))   #RK4
    if cnt == 1
      cache.k4 = k1
    elseif cnt == 2
      cache.k3 = k1
    else
      cache.k2 = k1
    end
  else
    u  = uprev + (dt/24)*(55*k1 - 59*k2 + 37*k3 - 9*k4)
    cache.k4 = k3
    cache.k3 = k2
    cache.k2 = k1
  end
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::AB4Cache)
  @unpack tmp,fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::AB4Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,k4,ralk2,k,t2,t3,t4 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 3
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    @. tmp = uprev + halfdt*k1
    f(t2,tmp,p,ttmp)
    @. tmp = uprev + halfdt*t2
    f(t3,tmp,p,ttmp)
    @. tmp = uprev + dt*t3
    f(t4,tmp,p,t+dt)
    @. u = uprev + (dt/6)*(2*(t2 + t3) + (k1 + t4))   #RK4
    if cnt == 1
      cache.k4 .= k1
    elseif cnt == 2
      cache.k3 .= k1
    else
      cache.k2 .= k1
    end
  else
    @. u  = uprev + (dt/24)*(55*k1 - 59*k2 + 37*k3 - 9*k4)
    cache.k4, cache.k3 = k3, k4
    cache.k3 .= k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

function initialize!(integrator,cache::ABM43ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::ABM43ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2,k3,k4 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 2
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    k2 = f(uprev + halfdt*k1, p, ttmp)
    k3 = f(uprev + halfdt*k2, p, ttmp)
    k4 = f(uprev + dt*k3, p, t+dt)
    u = uprev + (dt/6)*(2*(k2 + k3) + (k1+k4))   #RK4
    if cnt == 1
      cache.k3 = k1
    else
      cache.k2 = k1
    end
  else
    perform_step!(integrator, AB4ConstantCache(k2,k3,k4,cnt))
    k = integrator.fsallast
    u = uprev + (dt/24)*(9*k + 19*k1 - 5*k2 + k3)
    cache.k4 = k3
    cache.k3 = k2
    cache.k2 = k1
  end
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::ABM43Cache)
  @unpack fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::ABM43Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,k4,ralk2,k,t2,t3,t4,t5,t6,t7 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 2
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    @. tmp = uprev + halfdt*k1
    f(t2,tmp,p,ttmp)
    @. tmp = uprev + halfdt*t2
    f(t3,tmp,p,ttmp)
    @. tmp = uprev + dt*t3
    f(t4,tmp,p,t+dt)
    @. u = uprev + (dt/6)*(2*(t2 + t3) + (k1 + t4))   #RK4
    if cnt == 1
      cache.k3 .= k1
    else
      cache.k2 .= k1
    end
  else
    t2 .= k2
    t3 .= k3
    t4 .= k4
    perform_step!(integrator, AB4Cache(u,uprev,fsalfirst,t2,t3,t4,ralk2,k,tmp,t5,t6,t7,cnt))
    k = integrator.fsallast
    @. u = uprev + (dt/24)*(9*k + 19*k1 - 5*k2 + k3)
    cache.k4, cache.k3 = k3, k4
    cache.k3 .= k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

function initialize!(integrator,cache::AB5ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::AB5ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2,k3,k4,k5 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  if cache.step <= 4
    cnt = cache.step
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    k2 = f(uprev + halfdt*k1, p, ttmp)
    k3 = f(uprev + halfdt*k2, p, ttmp)
    k4 = f(uprev + dt*k3, p, t+dt)
    u = uprev + (dt/6)*(2*(k2 + k3) + (k1+k4))  #RK4
    if cnt == 1
      cache.k5 = k1
    elseif cnt == 2
      cache.k4 = k1
    elseif cnt == 3
      cache.k3 = k1
    else
      cache.k2 = k1
    end
  else
    u  = uprev + (dt/720)*(1901*k1 - 2774*k2 + 2616*k3 - 1274*k4 + 251*k5)
    cache.k5 = k4
    cache.k4 = k3
    cache.k3 = k2
    cache.k2 = k1
  end
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::AB5Cache)
  @unpack tmp,fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::AB5Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,k4,k5,k,t2,t3,t4 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 4
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    @. tmp = uprev + halfdt*k1
    f(t2,tmp,p,ttmp)
    @. tmp = uprev + halfdt*t2
    f(t3,tmp,p,ttmp)
    @. tmp = uprev + dt*t3
    f(t4,tmp,p,t+dt)
    @. u = uprev + (dt/6)*(2*(t2 + t3) + (k1 + t4))   #RK4
    if cnt == 1
      cache.k5 .= k1
    elseif cnt == 2
      cache.k4 .= k1
    elseif cnt == 3
      cache.k3 .= k1
    else
      cache.k2 .= k1
    end
  else
    @. u  = uprev + (dt/720)*(1901*k1 - 2774*k2 + 2616*k3 - 1274*k4 + 251*k5)
    cache.k5, cache.k4 = k4, k5
    cache.k4 .= k3
    cache.k3 .= k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

function initialize!(integrator,cache::ABM54ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::ABM54ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k2,k3,k4,k5 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 3
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    k2 = f(uprev + halfdt*k1, p, ttmp)
    k3 = f(uprev + halfdt*k2, p, ttmp)
    k4 = f(uprev + dt*k3, p, t+dt)
    u = uprev + (dt/6)*(2*(k2 + k3) + (k1+k4))   #RK4
    if cnt == 1
      cache.k4 = k1
    elseif cnt == 2
      cache.k3 = k1
    else
      cache.k2 = k1
    end
  else
    perform_step!(integrator, AB5ConstantCache(k2,k3,k4,k5,cnt))
    k = integrator.fsallast
    u = uprev + (dt/720)*(251*k + 646*k1 - 264*k2 + 106*k3 - 19*k4)
    cache.k5 = k4
    cache.k4 = k3
    cache.k3 = k2
    cache.k2 = k1
  end
  integrator.fsallast = f(u, p, t+dt)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.u = u
end

function initialize!(integrator,cache::ABM54Cache)
  @unpack fsalfirst,k = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::ABM54Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack tmp,fsalfirst,k2,k3,k4,k5,k,t2,t3,t4,t5,t6,t7,t8 = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  cnt = cache.step
  if cache.step <= 3
    cache.step += 1
    halfdt = dt/2
    ttmp = t+halfdt
    @. tmp = uprev + halfdt*k1
    f(t2,tmp,p,ttmp)
    @. tmp = uprev + halfdt*t2
    f(t3,tmp,p,ttmp)
    @. tmp = uprev + dt*t3
    f(t4,tmp,p,t+dt)
    @. u = uprev + (dt/6)*(2*(t2 + t3) + (k1 + t4))   #RK4
    if cnt == 1
      cache.k4 .= k1
    elseif cnt == 2
      cache.k3 .= k1
    else
      cache.k2 .= k1
    end
  else
    t2 .= k2
    t3 .= k3
    t4 .= k4
    t5 .= k5
    perform_step!(integrator, AB5Cache(u,uprev,fsalfirst,t2,t3,t4,t5,k,tmp,t6,t7,t8,cnt))
    k = integrator.fsallast
    @. u = uprev + (dt/720)*(251*k + 646*k1 - 264*k2 + 106*k3 - 19*k4)
    cache.k5, cache.k4 = k4, k5
    cache.k4 .= k3
    cache.k3 .= k2
    cache.k2 .= k1
  end
  f(k, u, p, t+dt)
end

# Variable Step Size Multistep Methods

function initialize!(integrator,cache::VCAB3ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCAB3ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕstar_n,ϕstar_nm1,order,tab = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2
    perform_step!(integrator, tab)
  else
    g_coefs!(cache,k)
    u = uprev
    for i = 1:k
        u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      utilde = dt * g[k] * ϕstar_n[k]      # Using lower order AB from subset of coefficients
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCAB3Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCAB3Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕstar_n,ϕstar_nm1,order,atmp,utilde,bs3cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache, k1, k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2
    perform_step!(integrator, bs3cache)
    @unpack k4 = bs3cache
    integrator.fsallast .= k4
  else
    g_coefs!(cache, k)
    @. u = uprev
    for i = 1:k
      @. u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      @. utilde = dt * g[k] * ϕstar_n[k]    # Using lower order AB from subset of coefficients
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end

function initialize!(integrator,cache::VCAB4ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCAB4ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕstar_n,ϕstar_nm1,order,rk4constcache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2 || k == 3
    perform_step!(integrator, rk4constcache)
  else
    g_coefs!(cache,k)
    u = uprev
    for i = 1:k
        u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      utilde = dt * g[k] * ϕstar_n[k]
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCAB4Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCAB4Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕ_n,ϕstar_n,ϕstar_nm1,order,atmp,utilde,rk4cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2 || k == 3
    rk4cache.fsalfirst .= k1
    perform_step!(integrator, rk4cache)
    integrator.fsallast .= rk4cache.k
  else
    g_coefs!(cache,k)
    @. u = uprev
    for i = 1:k
      @. u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      @. utilde = dt * g[k] * ϕstar_n[k]
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end

# VCAB5

function initialize!(integrator,cache::VCAB5ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCAB5ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕstar_n,ϕstar_nm1,order,rk4constcache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 4
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[5] = dts[4]
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2 || k == 3 || k == 4
    perform_step!(integrator, rk4constcache)
  else
    g_coefs!(cache,k)
    u = uprev
    for i = 1:k
        u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      utilde = dt * g[k] * ϕstar_n[k]
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCAB5Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCAB5Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕ_n,ϕstar_n,ϕstar_nm1,order,atmp,utilde,rk4cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 4
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[5] = dts[4]
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2 || k == 3 || k == 4
    rk4cache.fsalfirst .= k1
    perform_step!(integrator, rk4cache)
    integrator.fsallast .= rk4cache.k
  else
    g_coefs!(cache,k)
    @. u = uprev
    for i = 1:k
      @. u += dt * g[i] * ϕstar_n[i]
    end
    if integrator.opts.adaptive
      @. utilde = dt * g[k] * ϕstar_n[k]
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end

# VCABM3

function initialize!(integrator,cache::VCABM3ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCABM3ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕ_np1,ϕstar_n,ϕstar_nm1,order,tab = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2
    perform_step!(integrator, tab)
  else
    g_coefs!(cache,k+1)
    u = uprev
    for i = 1:(k-1)
        u += dt * g[i] * ϕstar_n[i]
    end
    du_np1 = f(u,p,t+dt)
    ϕ_np1!(cache, du_np1, k+1)
    u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCABM3Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCABM3Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕstar_n,ϕ_np1,ϕstar_nm1,order,atmp,utilde,bs3cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache, k1, k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2
    perform_step!(integrator, bs3cache)
    @unpack k4 = bs3cache
    integrator.fsallast .= k4
  else
    g_coefs!(cache, k+1)
    @. u = uprev
    for i = 1:(k-1)
      @. u += dt * g[i] * ϕstar_n[i]
    end
    f(k4,u,p,t+dt)
    ϕ_np1!(cache, k4, k+1)
    @. u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      @. utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end

# VCABM4

function initialize!(integrator,cache::VCABM4ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCABM4ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕ_np1,ϕstar_n,ϕstar_nm1,order,rk4constcache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2 || k == 3
    perform_step!(integrator, rk4constcache)
  else
    g_coefs!(cache,k+1)
    u = uprev
    for i = 1:(k-1)
        u += dt * g[i] * ϕstar_n[i]
    end
    du_np1 = f(u,p,t+dt)
    ϕ_np1!(cache, du_np1, k+1)
    u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCABM4Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCABM4Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕstar_n,ϕ_np1,ϕstar_nm1,order,atmp,utilde,rk4cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache, k1, k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2 || k == 3
    rk4cache.fsalfirst .= k1
    perform_step!(integrator, rk4cache)
    integrator.fsallast .= rk4cache.k
  else
    g_coefs!(cache, k+1)
    @. u = uprev
    for i = 1:(k-1)
      @. u += dt * g[i] * ϕstar_n[i]
    end
    f(k4,u,p,t+dt)
    ϕ_np1!(cache, k4, k+1)
    @. u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      @. utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end

# VCABM5

function initialize!(integrator,cache::VCABM5ConstantCache)
  integrator.fsalfirst = integrator.f(integrator.uprev, integrator.p, integrator.t) # Pre-start fsal
  integrator.kshortsize = 2
  integrator.k = typeof(integrator.k)(integrator.kshortsize)

  # Avoid undefined entries if k is an array of arrays
  integrator.fsallast = zero(integrator.fsalfirst)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
end

@muladd function perform_step!(integrator,cache::VCABM5ConstantCache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack dts,g,ϕ_n,ϕ_np1,ϕstar_n,ϕstar_nm1,order,rk4constcache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 4
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[5] = dts[4]
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  cache.ϕstar_nm1 .= ϕstar_n
  if k == 1 || k == 2 || k == 3 || k == 4
    perform_step!(integrator, rk4constcache)
  else
    g_coefs!(cache,k+1)
    u = uprev
    for i = 1:(k-1)
        u += dt * g[i] * ϕstar_n[i]
    end
    du_np1 = f(u,p,t+dt)
    ϕ_np1!(cache, du_np1, k+1)
    u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      atmp = calculate_residuals(utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    integrator.fsallast = f(u, p, t+dt)
    integrator.k[1] = integrator.fsalfirst
    integrator.k[2] = integrator.fsallast
    integrator.u = u
  end
end

function initialize!(integrator,cache::VCABM5Cache)
  @unpack fsalfirst,k4 = cache
  integrator.fsalfirst = fsalfirst
  integrator.fsallast = k4
  integrator.kshortsize = 2
  resize!(integrator.k, integrator.kshortsize)
  integrator.k[1] = integrator.fsalfirst
  integrator.k[2] = integrator.fsallast
  integrator.f(integrator.fsalfirst,integrator.uprev,integrator.p,integrator.t) # pre-start FSAL
end

@muladd function perform_step!(integrator,cache::VCABM5Cache,repeat_step=false)
  @unpack t,dt,uprev,u,f,p = integrator
  @unpack k4,dts,g,ϕ_n,ϕ_np1,ϕstar_n,ϕstar_nm1,order,atmp,utilde,rk4cache = cache
  k1 = integrator.fsalfirst
  if integrator.u_modified
    cache.step = 1
  end
  k = cache.step
  if k == 1
    dts[1] = dt
    cache.step += 1
  elseif k == 2
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 3
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  elseif k == 4
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
    cache.step += 1
  else
    dts[5] = dts[4]
    dts[4] = dts[3]
    dts[3] = dts[2]
    dts[2] = dts[1]
    dts[1] = dt
  end
  ϕ_and_ϕstar!(cache,k1,k)
  for i in eachindex(ϕstar_n)
    cache.ϕstar_nm1[i] .= ϕstar_n[i]
  end
  if k == 1 || k == 2 || k == 3 || k == 4
    rk4cache.fsalfirst .= k1
    perform_step!(integrator, rk4cache)
    integrator.fsallast .= rk4cache.k
  else
    g_coefs!(cache,k+1)
    @. u = uprev
    for i = 1:(k-1)
      @. u += dt * g[i] * ϕstar_n[i]
    end
    f(k4,u,p,t+dt)
    ϕ_np1!(cache, k4, k+1)
    @. u += dt * g[end-1] * ϕ_np1[end-1]
    if integrator.opts.adaptive
      @. utilde = dt * (g[end] - g[end-1]) * ϕ_np1[end]
      calculate_residuals!(atmp, utilde, uprev, u, integrator.opts.abstol, integrator.opts.reltol,integrator.opts.internalnorm)
      integrator.EEst = integrator.opts.internalnorm(atmp)
      if integrator.EEst >= one(integrator.EEst)
        return nothing
      end
    end
    f(k4,u,p,t+dt)
  end
end
