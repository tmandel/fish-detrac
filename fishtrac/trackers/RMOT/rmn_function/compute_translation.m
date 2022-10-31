function [Trans]=compute_translation(state)


Size = size(state,2);

if(Size>3)
    N = 1:Size-1;
    
    Trans1 = state(:,Size)-state(:,Size-N(1));
    Trans2 = state(:,Size-N(1))-state(:,Size-N(2));
    Trans3 = state(:,Size-N(2))-state(:,Size-N(3));
    
    Trans = 0.33*Trans1 + 0.33*Trans2 + 0.33*Trans3;
else
    
    N = 1:Size-1;
    
    Trans1 = state(:,Size)-state(:,Size-N(1));
    Trans2 = state(:,Size-N(1))-state(:,Size-N(2));
    
    Trans = 0.5*Trans1 + 0.5*Trans2;
end
