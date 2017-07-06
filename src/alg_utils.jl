isautodifferentiable(alg::OrdinaryDiffEqAlgorithm) = true

isfsal(alg::OrdinaryDiffEqAlgorithm) = false
isfsal(alg::DP5) = true
isfsal(alg::DP5Threaded) = true
isfsal(alg::DP8) = true
isfsal(alg::BS3) = true
isfsal(alg::BS5) = true
isfsal(alg::Tsit5) = true
isfsal(alg::Vern6) = true
isfsal(alg::Rosenbrock23) = true
isfsal(alg::Rosenbrock32) = true
isfsal(alg::ROS3P) = true
isfsal(alg::Rodas3) = true
isfsal(alg::RosShamp4) = true
isfsal(alg::Veldd4) = true
isfsal(alg::Velds4) = true
isfsal(alg::GRK4T) = true
isfsal(alg::GRK4A) = true
isfsal(alg::Ros4LStab) = true
isfsal(alg::Rodas4) = true
isfsal(alg::Rodas42) = true
isfsal(alg::Rodas4P) = true
isfsal(alg::LawsonEuler) = true
isfsal(alg::NorsettEuler) = true
isfsal(alg::Euler) = true
isfsal(alg::SplitEuler) = true
isfsal(alg::Midpoint) = true
isfsal(alg::SSPRK22) = true
isfsal(alg::SSPRK33) = true
isfsal(alg::SSPRK432) = true
isfsal(alg::SSPRK104) = true
isfsal(alg::RK4) = true
isfsal(alg::IIF1) = true
isfsal(alg::IIF2) = true
isfsal(alg::Feagin10) = true
isfsal(alg::Feagin12) = true
isfsal(alg::Feagin14) = true
isfsal(alg::TanYam7) = true
isfsal(alg::TsitPap8) = true
isfsal(alg::Trapezoid) = true
isfsal(alg::ImplicitEuler) = true
isfsal(alg::ExplicitRK) = true
isfsal{MType,VType,fsal}(tab::ExplicitRKTableau{MType,VType,fsal}) = fsal
#isfsal(tab::ImplicitRKTableau) = false
isfsal(alg::CompositeAlgorithm) = true # Every algorithm is assumed FSAL. Good assumption?

isfsal(alg::SymplecticEuler) = true
isfsal(alg::VelocityVerlet) = true
isfsal(alg::VerletLeapfrog) = true
isfsal(alg::PseudoVerletLeapfrog) = true
isfsal(alg::McAte2) = true
isfsal(alg::Ruth3) = true
isfsal(alg::McAte3) = true
isfsal(alg::CandyRoz4) = true
isfsal(alg::CalvoSanz4) = true
isfsal(alg::McAte4) = true
isfsal(alg::McAte42) = true
isfsal(alg::McAte5) = true
isfsal(alg::Yoshida6) = true
isfsal(alg::KahanLi6) = true
isfsal(alg::McAte8) = true
isfsal(alg::KahanLi8) = true
isfsal(alg::SofSpa10) = true

fsal_typeof(alg::OrdinaryDiffEqAlgorithm,rate_prototype) = typeof(rate_prototype)
#fsal_typeof(alg::LawsonEuler,rate_prototype) = Vector{typeof(rate_prototype)}
#fsal_typeof(alg::NorsettEuler,rate_prototype) = Vector{typeof(rate_prototype)}

isimplicit(alg::OrdinaryDiffEqAlgorithm) = false
isimplicit(alg::ImplicitEuler) = true
isimplicit(alg::Trapezoid) = true
isimplicit(alg::IIF1) = true
isimplicit(alg::IIF2) = true

isdtchangeable(alg::OrdinaryDiffEqAlgorithm) = true

ismultistep(alg::OrdinaryDiffEqAlgorithm) = false

isadaptive(alg::OrdinaryDiffEqAlgorithm) = false
isadaptive(alg::OrdinaryDiffEqAdaptiveAlgorithm) = true
isadaptive(alg::OrdinaryDiffEqCompositeAlgorithm) = isadaptive(alg.algs[1])

qmin_default(alg::OrdinaryDiffEqAlgorithm) = 1//5
qmin_default(alg::DP8) = 1//3

qmax_default(alg::OrdinaryDiffEqAlgorithm) = 10
qmax_default(alg::DP8) = 6

get_chunksize(alg::OrdinaryDiffEqAlgorithm) = error("This algorithm does not have a chunk size defined.")
get_chunksize{CS,AD}(alg::Rosenbrock23{CS,AD}) = CS
get_chunksize{CS,AD}(alg::Rosenbrock32{CS,AD}) = CS
get_chunksize{CS,AD}(alg::ROS3P{CS,AD}) = CS
get_chunksize{CS,AD}(alg::Rodas3{CS,AD}) = CS
get_chunksize{CS,AD}(alg::RosShamp4{CS,AD}) = CS
get_chunksize{CS,AD}(alg::Veldd4{CS,AD}) = CS
get_chunksize{CS,AD}(alg::Velds4{CS,AD}) = CS
get_chunksize{CS,AD}(alg::GRK4T{CS,AD}) = CS
get_chunksize{CS,AD}(alg::GRK4A{CS,AD}) = CS
get_chunksize{CS,AD}(alg::Ros4LStab{CS,AD}) = CS


alg_extrapolates(alg::OrdinaryDiffEqAlgorithm) = false
alg_extrapolates(alg::ImplicitEuler) = true
alg_extrapolates(alg::Trapezoid) = true

alg_autodiff(alg::OrdinaryDiffEqAlgorithm) = error("This algorithm does not have an autodifferentiation option defined.")
alg_autodiff{CS,AD}(alg::Rosenbrock23{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::Rosenbrock32{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::ROS3P{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::Rodas3{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::RosShamp4{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::Veldd4{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::Velds4{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::GRK4T{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::GRK4A{CS,AD}) = AD
alg_autodiff{CS,AD}(alg::Ros4LStab{CS,AD}) = AD


alg_order(alg::OrdinaryDiffEqAlgorithm) = error("Order is not defined for this algorithm")
alg_adaptive_order(alg::OrdinaryDiffEqAdaptiveAlgorithm) = error("Algorithm is adaptive with no order")

alg_order(alg::Discrete) = 0
alg_order(alg::Euler) = 1
alg_order(alg::LawsonEuler) = 1
alg_order(alg::NorsettEuler) = 1
alg_order(alg::SplitEuler) = 1

alg_order(alg::SymplecticEuler) = 1
alg_order(alg::VelocityVerlet) = 2
alg_order(alg::VerletLeapfrog) = 2
alg_order(alg::PseudoVerletLeapfrog) = 2
alg_order(alg::McAte2) = 2
alg_order(alg::Ruth3) = 3
alg_order(alg::McAte3) = 3
alg_order(alg::McAte4) = 4
alg_order(alg::CandyRoz4) = 4
alg_order(alg::CalvoSanz4) = 4
alg_order(alg::McAte42) = 4
alg_order(alg::McAte5) = 5
alg_order(alg::Yoshida6) = 6
alg_order(alg::KahanLi6) = 6
alg_order(alg::McAte8) = 8
alg_order(alg::KahanLi8) = 8
alg_order(alg::SofSpa10) = 10

alg_order(alg::Midpoint) = 2
alg_order(alg::IIF1) = 1
alg_order(alg::IIF2) = 2
alg_order(alg::SSPRK22) = 2
alg_order(alg::SSPRK33) = 3
alg_order(alg::SSPRK432) = 3
alg_order(alg::SSPRK104) = 4
alg_order(alg::RK4) = 4
alg_order(alg::ExplicitRK) = alg.tableau.order
alg_order(alg::BS3) = 3
alg_order(alg::BS5) = 5
alg_order(alg::DP5) = 5
alg_order(alg::DP5Threaded) = 5
alg_order(alg::Tsit5) = 5
alg_order(alg::DP8) = 8
alg_order(alg::Vern6) = 6
alg_order(alg::Vern7) = 7
alg_order(alg::Vern8) = 8
alg_order(alg::Vern9) = 9
alg_order(alg::TanYam7) = 7
alg_order(alg::TsitPap8) = 8
alg_order(alg::ImplicitEuler) = 1
alg_order(alg::Trapezoid) = 2
alg_order(alg::Feagin10) = 10
alg_order(alg::Feagin12) = 12
alg_order(alg::Feagin14) = 14

alg_order(alg::Rosenbrock23) = 2
alg_order(alg::Rosenbrock32) = 3
alg_order(alg::ROS3P) = 3
alg_order(alg::Rodas3) = 3
alg_order(alg::RosShamp4) = 4
alg_order(alg::Veldd4) = 4
alg_order(alg::Velds4) = 4
alg_order(alg::GRK4T) = 4
alg_order(alg::GRK4A) = 4
alg_order(alg::Ros4LStab) = 4
alg_order(alg::Rodas4) = 4
alg_order(alg::Rodas42) = 4
alg_order(alg::Rodas4P) = 4

alg_order(alg::CompositeAlgorithm) = alg_order(alg.algs[1])

alg_adaptive_order(alg::ExplicitRK) = alg.tableau.adaptiveorder
alg_adaptive_order(alg::SSPRK432) = 2
alg_adaptive_order(alg::BS3) = 2
alg_adaptive_order(alg::BS5) = 4
alg_adaptive_order(alg::DP5) = 4
alg_adaptive_order(alg::DP5Threaded) = 4
alg_adaptive_order(alg::Tsit5) = 4
alg_adaptive_order(alg::DP8) = 6
alg_adaptive_order(alg::Vern6) = 5
alg_adaptive_order(alg::Vern7) = 6
alg_adaptive_order(alg::Vern8) = 7
alg_adaptive_order(alg::Vern9) = 8
alg_adaptive_order(alg::TanYam7) = 6
alg_adaptive_order(alg::TsitPap8) = 7
alg_adaptive_order(alg::Feagin10) = 8
alg_adaptive_order(alg::Feagin12) = 10
alg_adaptive_order(alg::Feagin14) = 12

alg_adaptive_order(alg::Rosenbrock23) = 3
alg_adaptive_order(alg::Rosenbrock32) = 2
alg_adaptive_order(alg::ROS3P) = 2
alg_adaptive_order(alg::Rodas3) = 2
alg_adaptive_order(alg::RosShamp4) = 3
alg_adaptive_order(alg::Veldd4) = 3
alg_adaptive_order(alg::Velds4) = 3
alg_adaptive_order(alg::GRK4T) = 3
alg_adaptive_order(alg::GRK4A) = 3
alg_adaptive_order(alg::Ros4LStab) = 3
alg_adaptive_order(alg::Rodas4) = 3
alg_adaptive_order(alg::Rodas42) = 3
alg_adaptive_order(alg::Rodas4P) = 3

beta2_default(alg::OrdinaryDiffEqAlgorithm) = 2//(5alg_order(alg))
beta2_default(alg::Discrete) = 0
beta2_default(alg::DP8) = 0//1
beta2_default(alg::DP5) = 4//100
beta2_default(alg::DP5Threaded) = 4//100

beta1_default(alg::OrdinaryDiffEqAlgorithm,beta2) = 7//(10alg_order(alg))
beta1_default(alg::Discrete,beta2) = 0
beta1_default(alg::DP8,beta2) = typeof(beta2)(1//alg_order(alg)) - beta2/5
beta1_default(alg::DP5,beta2) = typeof(beta2)(1//alg_order(alg)) - 3beta2/4
beta1_default(alg::DP5Threaded,beta2) = typeof(beta2)(1//alg_order(alg)) - 3beta2/4

discrete_apply_map{apply_map,scale_by_time}(alg::Discrete{apply_map,scale_by_time}) = apply_map
discrete_scale_by_time{apply_map,scale_by_time}(alg::Discrete{apply_map,scale_by_time}) = scale_by_time
