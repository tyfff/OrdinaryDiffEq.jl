# exponential_utils.jl
# Contains functions related to the evaluation of scalar/matrix phi functions 
# that are used by the exponential integrators.
#
# TODO: write a version of `expm!` that is non-allocating.

###################################################
# Dense algorithms
const exp! = Base.LinAlg.expm! # v0.7 style

"""
    phi(z,k[;cache]) -> [phi_0(z),phi_1(z),...,phi_k(z)]

Compute the scalar phi functions for all orders up to k.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Instead of using the recurrence relation, which is numerically unstable, a 
formula given by Sidje is used (Sidje, R. B. (1998). Expokit: a software 
package for computing matrix exponentials. ACM Transactions on Mathematical 
Software (TOMS), 24(1), 130-156. Theorem 1).
"""
function phi(z::T, k::Integer; cache=nothing) where {T <: Number}
  # Construct the matrix
  if cache == nothing
    cache = zeros(T, k+1, k+1)
  else
    fill!(cache, zero(T))
  end
  cache[1,1] = z
  for i = 1:k
    cache[i,i+1] = one(T)
  end
  P = exp!(cache)
  return P[1,:]
end

"""
    phiv_dense(A,v,k[;cache]) -> [phi_0(A)v phi_1(A)v ... phi_k(A)v]

Compute the matrix-phi-vector products for small, dense `A`. `k`` >= 1.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Instead of using the recurrence relation, which is numerically unstable, a 
formula given by Sidje is used (Sidje, R. B. (1998). Expokit: a software 
package for computing matrix exponentials. ACM Transactions on Mathematical 
Software (TOMS), 24(1), 130-156. Theorem 1).
"""
function phiv_dense(A, v, k; cache=nothing)
  w = Matrix{eltype(A)}(length(v), k+1)
  phiv_dense!(w, A, v, k; cache=cache)
end
"""
    phiv_dense!(w,A,v,k[;cache]) -> w

Non-allocating version of `phiv_dense`.
"""
function phiv_dense!(w::AbstractMatrix{T}, A::AbstractMatrix{T}, 
  v::AbstractVector{T}, k::Integer; cache=nothing) where {T <: Number}
  @assert size(w, 1) == size(A, 1) == size(A, 2) == length(v) "Dimension mismatch"
  @assert size(w, 2) == k+1 "Dimension mismatch"
  m = length(v)
  # Construct the extended matrix
  if cache == nothing
    cache = zeros(T, m+k, m+k)
  else
    @assert size(cache) == (m+k, m+k) "Dimension mismatch"
    fill!(cache, zero(T))
  end
  cache[1:m, 1:m] = A
  cache[1:m, m+1] = v
  for i = m+1:m+k-1
    cache[i, i+1] = one(T)
  end
  P = exp!(cache)
  # Extract results
  @views A_mul_B!(w[:, 1], P[1:m, 1:m], v)
  @inbounds for i = 1:k
    @inbounds for j = 1:m
      w[j, i+1] = P[j, m+i]
    end
  end
  return w
end

"""
    phi(A,k[;cache]) -> [phi_0(A),phi_1(A),...,phi_k(A)]

Compute the matrix phi functions for all orders up to k. `k` >= 1.

The phi functions are defined as
  
```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

Calls `phiv_dense` on each of the basis vectors to obtain the answer.
"""
function phi(A::AbstractMatrix{T}, k; caches=nothing) where {T <: Number}
  m = size(A, 1)
  out = [Matrix{T}(m, m) for i = 1:k+1]
  phi!(out, A, k; caches=caches)
end
"""
    phi!(out,A,k[;caches]) -> out

Non-allocating version of `phi` for matrix inputs.
"""
function phi!(out::Vector{Matrix{T}}, A::AbstractMatrix{T}, k::Integer; caches=nothing) where {T <: Number}
  m = size(A, 1)
  @assert length(out) == k + 1 && all(P -> size(P) == (m,m), out) "Dimension mismatch"
  if caches == nothing
    e = Vector{T}(m)
    W = Matrix{T}(m, k+1)
    C = Matrix{T}(m+k, m+k)
  else
    e, W, C = caches
    @assert size(e) == (m,) && size(W) == (m, k+1) && size(C) == (m+k, m+k) "Dimension mismatch"
  end
  @inbounds for i = 1:m
    fill!(e, zero(T)); e[i] = one(T) # e is the ith basis vector
    phiv_dense!(W, A, e, k; cache=C) # W = [phi_0(A)*e phi_1(A)*e ... phi_k(A)*e]
    @inbounds for j = 1:k+1
      @inbounds for s = 1:m
        out[j][s, i] = W[s, j]
      end
    end
  end
  return out
end

##############################################
# Krylov algorithms
"""
    KrylovSubspace{T}(n,[maxiter=30]) -> Ks

Constructs an uninitialized Krylov subspace, which can be filled by `arnoldi!`.

The dimension of the subspace, `Ks.m`, can be dynamically altered but should 
be smaller than `maxiter`, the maximum allowed arnoldi iterations.

    getV(Ks) -> V
    getH(Ks) -> H

Access methods for orthonormal basis `V` and the Gram-Schmidt coefficients `H`. 
Both methods return a view into the storage arrays and has the correct 
dimensions as indicated by `Ks.m`.

    resize!(Ks, maxiter) -> Ks

Resize `Ks` to a different `maxiter`, destroying its contents.

This is an expensive operation and should be used scarsely.
"""
mutable struct KrylovSubspace{B, T}
  m::Int        # subspace dimension
  maxiter::Int  # maximum allowed subspace size
  beta::B       # norm(b,2)
  V::Matrix{T}  # orthonormal bases
  H::Matrix{T}  # Gram-Schmidt coefficients
  KrylovSubspace{T}(n::Integer, maxiter::Integer=30) where {T} = new{real(T), T}(
    maxiter, maxiter, zero(real(T)), Matrix{T}(n, maxiter), zeros(T, maxiter, maxiter))
end
# TODO: switch to overload `getproperty` in v0.7
getH(Ks::KrylovSubspace) = @view(Ks.H[1:Ks.m, 1:Ks.m])
getV(Ks::KrylovSubspace) = @view(Ks.V[:, 1:Ks.m])
function Base.resize!(Ks::KrylovSubspace{B,T}, maxiter::Integer) where {B,T}
  V = Matrix{T}(size(Ks.V, 1), maxiter)
  H = zeros(T, maxiter, maxiter)
  Ks.V = V; Ks.H = H
  Ks.m = Ks.maxiter = maxiter
  return Ks
end
function Base.show(io::IO, Ks::KrylovSubspace)
  println(io, "$(Ks.m)-dimensional Krylov subspace with fields")
  println(io, "beta: $(Ks.beta)")
  print(io, "V: ")
  println(IOContext(io, limit=true), getV(Ks))
  print(io, "H: ")
  println(IOContext(io, limit=true), getH(Ks))
end

"""
    arnoldi(A,b[;m,tol,norm,cache]) -> Ks

Performs `m` anoldi iterations to obtain the Krylov subspace K_m(A,b).

The n x m unitary basis vectors `getV(Ks)` and the m x m upper Heisenberg 
matrix `getH(Ks)` are related by the recurrence formula

```
v_1=b,\\quad Av_j = \\sum_{i=1}^{j+1}h_{ij}v_i\\quad(j = 1,2,\\ldots,m)
```

Refer to `KrylovSubspace` for more information regarding the output.

Happy-breakdown occurs whenver `norm(v_j) < tol * norm(A, Inf)`, in this case 
the dimension of `Ks` is smaller than `m`.
"""
function arnoldi(A, b; m=min(30, size(A, 1)), tol=1e-7, norm=Base.norm, 
  cache=nothing)
  Ks = KrylovSubspace{eltype(b)}(length(b), m)
  arnoldi!(Ks, A, b; m=m, tol=tol, norm=norm, cache=cache)
end
"""
    arnoldi!(Ks,A,b[;tol,m,norm,cache]) -> Ks

Non-allocating version of `arnoldi`.
"""
function arnoldi!(Ks::KrylovSubspace{B, T}, A, b::AbstractVector{T}; tol=1e-7, 
  m=min(Ks.maxiter, size(A, 1)), norm=Base.norm, cache=nothing) where {B, T <: Number}
  if ishermitian(A)
    return lanczos!(Ks, A, b; tol=tol, m=m, norm=norm, cache=cache)
  end
  if m > Ks.maxiter
    resize!(Ks, m)
  else
    Ks.m = m # might change if happy-breakdown occurs
  end
  V, H = getV(Ks), getH(Ks)
  vtol = tol * norm(A, Inf)
  # Safe checks
  n = size(V, 1)
  @assert length(b) == size(A,1) == size(A,2) == n "Dimension mismatch"
  if cache == nothing
    cache = similar(b)
  else
    @assert size(cache) == (n,) "Dimension mismatch"
  end
  # Arnoldi iterations
  fill!(H, zero(T))
  Ks.beta = norm(b)
  V[:, 1] = b / Ks.beta
  @inbounds for j = 1:m
    A_mul_B!(cache, A, @view(V[:, j]))
    @inbounds for i = 1:j
      alpha = dot(@view(V[:, i]), cache)
      H[i, j] = alpha
      Base.axpy!(-alpha, @view(V[:, i]), cache)
    end
    beta = norm(cache)
    if beta < vtol || j == m
      # happy-breakdown or maximum iteration is reached
      Ks.m = j
      return Ks
    end
    H[j+1, j] = beta
    @inbounds for i = 1:n
      V[i, j+1] = cache[i] / beta
    end
  end
end
"""
    lanczos!(Ks,A,b[;tol,m,norm,cache]) -> Ks

A variation of `arnoldi!` that uses the Lanczos algorithm for Hermitian matrices.
"""
function lanczos!(Ks::KrylovSubspace{B, T}, A, b::AbstractVector{T}; tol=1e-7,
  m=min(Ks.maxiter, size(A, 1)), norm=Base.norm, cache=nothing) where {B, T <: Number}
  if m > Ks.maxiter
    resize!(Ks, m)
  else
    Ks.m = m # might change if happy-breakdown occurs
  end
  V, H = getV(Ks), getH(Ks)
  vtol = tol * norm(A, Inf)
  # Safe checks
  n = size(V, 1)
  @assert length(b) == size(A,1) == size(A,2) == n "Dimension mismatch"
  if cache == nothing
    cache = similar(b)
  else
    @assert size(cache) == (n,) "Dimension mismatch"
  end
  # Lanczos iterations
  fill!(H, zero(T))
  Ks.beta = norm(b)
  V[:, 1] = b / Ks.beta
  @inbounds for j = 1:m
    vj = @view(V[:, j])
    A_mul_B!(cache, A, vj)
    alpha = dot(vj, cache)
    H[j, j] = alpha
    Base.axpy!(-alpha, vj, cache)
    if j > 1
      Base.axpy!(-H[j-1, j], @view(V[:, j-1]), cache)
    end
    beta = norm(cache)
    if beta < vtol || j == m
      # happy-breakdown or maximum iteration is reached
      Ks.m = j
      return Ks
    end
    H[j+1, j] = H[j, j+1] = beta
    @inbounds for i = 1:n
      V[i, j+1] = cache[i] / beta
    end
  end
end

"""
    expv(t,A,b; kwargs) -> exp(tA)b

Compute the matrix-exponential-vector product using Krylov.

A Krylov subspace is constructed using `arnoldi` and `expm!` is called 
on the Heisenberg matrix. Consult `arnoldi` for the values of the keyword 
arguments.
"""
function expv(t, A, b; m=min(30, size(A, 1)), tol=1e-7, norm=Base.norm, cache=nothing)
  Ks = arnoldi(A, b; m=m, tol=tol, norm=norm)
  w = similar(b)
  expv!(w, t, Ks; cache=cache)
end
"""
    expv!(w,t,Ks[;cache]) -> w

Non-allocating version of `expv` that uses precomputed Krylov subspace `Ks`.
"""
function expv!(w::Vector{T}, t::Number, Ks::KrylovSubspace{B, T}; 
  cache=nothing) where {B, T <: Number}
  m, beta, V, H = Ks.m, Ks.beta, getV(Ks), getH(Ks)
  @assert length(w) == size(V, 1) "Dimension mismatch"
  if cache == nothing
    cache = Matrix{T}(m, m)
  else
    # The cache may have a bigger size to handle different values of m.
    # Here we only need a portion.
    cache = @view(cache[1:m, 1:m])
  end
  @. cache = t * H
  if ishermitian(cache)
    # Optimize the case for symtridiagonal H
    F = eigfact!(SymTridiagonal(cache)) # Note: eigfact! -> eigen! in v0.7
    expHe = F.vectors * (exp.(F.values) .* @view(F.vectors[1, :]))
  else
    expH = exp!(cache)
    expHe = @view(expH[:, 1])
  end
  scale!(beta, A_mul_B!(w, V, expHe)) # exp(A) ≈ norm(b) * V * exp(H)e
end

"""
    phiv(t,A,b,k; kwargs) -> [phi_0(tA)b phi_1(tA)b ... phi_k(tA)b]

Compute the matrix-phi-vector products using Krylov. `k` >= 1.

The phi functions are defined as

```math
\\varphi_0(z) = \\exp(z),\\quad \\varphi_k(z+1) = \\frac{\\varphi_k(z) - 1}{z} 
```

A Krylov subspace is constructed using `arnoldi` and `phiv_dense` is called 
on the Heisenberg matrix. Consult `arnoldi` for the values of the keyword 
arguments.
"""
function phiv(t, A, b, k; m=min(30, size(A, 1)), tol=1e-7, norm=Base.norm, 
  caches=nothing)
  Ks = arnoldi(A, b; m=m, tol=tol, norm=norm)
  w = Matrix{eltype(b)}(length(b), k+1)
  phiv!(w, t, Ks, k; caches=caches)
end
"""
    phiv!(w,t,Ks,k[;caches]) -> w

Non-allocating version of 'phiv' that uses precomputed Krylov subspace `Ks`.
"""
function phiv!(w::Matrix{T}, t::Number, Ks::KrylovSubspace{B, T}, k::Integer; 
  caches=nothing) where {B, T <: Number}
  m, beta, V, H = Ks.m, Ks.beta, getV(Ks), getH(Ks)
  @assert size(w, 1) == size(V, 1) "Dimension mismatch"
  @assert size(w, 2) == k + 1 "Dimension mismatch"
  if caches == nothing
    e = Vector{T}(m)
    Hcopy = Matrix{T}(m, m)
    C1 = Matrix{T}(m + k, m + k)
    C2 = Matrix{T}(m, k + 1)
  else
    e, Hcopy, C1, C2 = caches
    # The caches may have a bigger size to handle different values of m.
    # Here we only need a portion of them.
    e = @view(e[1:m])
    Hcopy = @view(Hcopy[1:m, 1:m])
    C1 = @view(C1[1:m + k, 1:m + k])
    C2 = @view(C2[1:m, 1:k + 1])
  end
  @. Hcopy = t * H
  fill!(e, zero(T)); e[1] = one(T) # e is the [1,0,...,0] basis vector
  phiv_dense!(C2, Hcopy, e, k; cache=C1) # C2 = [ϕ0(H)e ϕ1(H)e ... ϕk(H)e]
  scale!(beta, A_mul_B!(w, V, C2)) # f(A) ≈ norm(b) * V * f(H)e
end
