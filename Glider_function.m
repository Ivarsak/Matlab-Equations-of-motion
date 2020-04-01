function T=Glider(T,y)

load('Glider_variables');

R =         y(1:3);                 %R(1) = Phi, R(2) = Theta, R(3) = Psi
b =         y(4:6);                 %b(1) = x, b(2) = y, b(3) = z in earth frame
omega =     y(7:9);                 %omega(1) = p, omega(2) = q, omega(3) = r
V =         y(10:12);               %V(1) = V1, V(2) = V2, V(3) = V3 in body frame
rp =        y(13:15);               %rp(1) = rp1, rp(2) = rp2, rp(3) = rp3 position of moving mass block
rb =        y(16:18);               %rb(1,2,3) = 0 position of ballast mass,
r_gamma =   y(19:21);               %r_gamma(1) = 0, r_gamma(2) = Gamma, r_gamma(3) = 0 position of rolling mass block
mb =        y(22);                  %mb -> ballast mass

R_sim = R*(180/pi)

Alpha = atan(V(3)/V(1));                              %Angle of attack
Beta  = atan(V(2)/(sqrt(V(1)^2 + V(2)^2 +V(3)^2)));   %Sideslip angle

 

rb =  [0 0 0]';                    %Position of ballast mass (neglected)
u1 =  [0 0 0]';                    %Control input for longitudal moving mass (constant)
u2 =  [0 0 0]';                    %Control input for lateral moving mass (constant)
u3 =  0;                           %Control input for ballast mass (constant)
u4 =  [0 0 0]';                     %Control input for ballast mass position (neglected)
 

%Position of the movable block
rr = rp1_d*N + Rr*((cos(Gamma_d + (pi/2)))*E + (sin(Gamma_d + pi/2))*D);


   %% Computing Hydrodynamic forces
   
   vf = (V(1)^2 + V(2)^2 + V(3)^2);             

   D_1 = (KD0 + (KD*(Alpha^2)))*vf;             %Drag
   SF = (K_beta*Beta)*vf;                       %Sideforce
   L = (KL0 + K_alpha*Alpha)*vf;                %Lift
   
   MDL_1 = (KMR*Beta + Kp*omega(1))*vf;         %Roll Moment
   MDL_2 = (KM0 + KM*Alpha + Kq*omega(2))*vf;   %Pitch Moment
   MDL_3 = (KMY*Beta + Kr*omega(3))*vf;         %Yaw Moment
   
   F_ext = [-D_1 SF -L]';                       %Total Hydrodynamic force
   T_ext = [MDL_1 MDL_2 MDL_3]';                %Total hydrodynamic moment


 %Rotation matrix from body frame to flow frame
    R_BF = [cos(Alpha)*cos(Beta) -cos(Alpha)*sin(Beta) -sin(Alpha);
            sin(Beta) cos(Beta) 0;
            sin(Alpha)*cos(Beta) -sin(Alpha)*sin(Beta) cos(Alpha)];
   
  
  

%% Kinematics

% Rotation matrix to map the angular velocities in the body frame
R_1 = [1 sin(R(1))* tan(R(2)) cos(R(1))*tan(R(2));
       0    cos(R(1))            -sin(R(1));
       0 sin(R(1))*sec(R(2))    cos(R(1))*sec(R(2))];
   

%Rotation matrix to map the translational velocities in the body frame
R_2 = [cos(R(3))*cos(R(2))    (-sin(R(3))*cos(R(1)) + cos(R(3))*sin(R(2))*sin(R(1))) (sin(R(3))*sin(R(1)) + cos(R(3))*cos(R(1))*sin(R(2)));
     sin(R(3))*cos(R(2))    (cos(R(3))*cos(R(1)) + sin(R(1))*sin(R(2))*sin(R(3)))  (-cos(R(3))*sin(R(1)) + sin(R(2))*sin(R(3))*cos(R(1)));
     -sin(R(2))            cos(R(2))*sin(R(1))                                 cos(R(2))*cos(R(1))];

 
%Inertia matrix for the rolling mass
R_x = [1 0 0;
       0 cos(Gamma_d) -sin(Gamma_d);
       0 sin(Gamma_d) cos(Gamma_d)];
   
 
%Position of the movable block
rr = rp1_d*N + Rr*((cos(Gamma_d + (pi/2)))*E + (sin(Gamma_d + pi/2))*D); 
   
   
 %% Computing Skew symmetric matrices for moving mass and static mass
   
 
 rrb_hat = [0 -r_rb3 r_rb2;       %Skew symmetric matrix of static block r_rb 
          r_rb3 0 -r_rb1;
          -r_rb2 r_rb1 0];

 rp_hat = [0 -rr(3) rr(2);        %Skew symmetric movable block rr 
          rr(3) 0 -rr(1);
          -rr(2) rr(1) 0];

 
%% Computing the Dynamic equation
 %Note: Position of the linear ballast mass are neglected in the
 %generalized inertia matrix and the dynamic equations
   
M11 =  M_A + ((mrb + mp + mb)*I3);
M12 =  C_A - mrb*rrb_hat - mp*rp_hat; 
M21 =  C_A' + (-mrb*rrb_hat - mp*rp_hat)';
M22 =  I_A + I_rb + (R_x'*I_rm*R_x) - mp*rp_hat*rp_hat - mrb*rrb_hat*rrb_hat;


M = [M11 M12;                %Generalized inertia matrix
     M21 M22];


 u = M*[V; omega];           %Generalized momentum
 
 P = [u(1) u(2) u(3)]';      %Translational Momentum 
 P_Ang = [u(4) u(5) u(6)]';  %Angular Momentum 
 
 
% Dynamic Equation
v_dot = inv(M)*(-M*[V; omega] + [cross(P, omega); cross(P_Ang, omega) + cross(P,V)] + [mb*g*R_2'*D; cross((mrb*rrb + mp*rr + mb*rb)*g,(R_2'*D))] + [R_2'*F_ext; R_2'*T_ext]);


%% Equations of motion in 3D


V_dot =     [v_dot(1) v_dot(2) v_dot(3)]';      %Dynamic equation 
omega_dot = [v_dot(4) v_dot(5) v_dot(6)]';      %Dyamic equation 
R_dot =     R_1*omega;                          %Kinematic equation   
b_dot =     R_2*V;                              %Kinematic equation 


%Control inputs --> Only constant/initial conditions in this simulation

rp1_dot =   u1;         %change rate = [0 0 0]'
Gamma_dot = u2;         %change rate = [0 0 0]'
rb_dot =    u4;         %change rate = [0 0 0]'
mb_dot =    u3;         %change rate = 0




%Return vector for the ODE45 solver
T =[R_dot' b_dot' omega_dot' V_dot' rp1_dot' rb_dot' Gamma_dot' mb_dot']'; 

    
end
