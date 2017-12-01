% Abstract superclass for coordinate systems
% Anthony Riccairdi
%
classdef (Abstract) cord < matlab.mixin.Heterogeneous
    
    properties (Abstract)
        CID % (Integer > 0) Coordinate system identification number.
        RID % (Integer >= 0) Identification number of a coordinate system that is defined independently from this coordinate system. 
        XC_0 % ([3,1] Float) Csys location in basic coordinate system.
        TC_C0 % ([3,3] Symmetric Float) Transformation matrix from basic coordinate system to current coordinate system at current coordinate system origin
    end
    
    methods (Abstract)
        XP_0 = XP_0(obj,XP_C) % Returns location XP ([3,1] Float) expressed in _0 from XP expressed in _C
        XP_C = XP_C(obj,XP_0) % Returns location XP ([3,1] Float) expressed in _C from XP expressed in _0
        T_C0 = T_C0(obj,XP_C) % Returns transformation matrix ([3,3] Symmetric Float) from basic coordinate system to current coordinate system at XP_C
    end
    
    methods (Sealed = true)
        function obj = preprocess(obj)
            % function to preprocess coordinate systems
            [ncord,m]=size(obj);
            if m > 1; error('cord.preprocess() can only handel nx1 arrays of cord objects. The second dimension exceeds 1.'); end
            
            % check that element id numbers are unique
            CIDS=[obj.CID];
            [~,ia] = unique(CIDS,'stable');
            if size(ia,1)~=ncord
                nonunique=setxor(ia,1:ncord);
                error('Element identification numbers should be unique. Nonunique element identification number(s): %s',sprintf('%d,',CIDS(nonunique)))
            end
            
            % Create basic coordinate system and add to array
            Robj = cord2r; Robj.XC_0=zeros(3,1); Robj.TC_C0=eye(3); % Basic Csys
            Robj.CID = 0; Robj.RID = -1;
            obj = [Robj;obj];
            
            % preprocess coordinate systems accounting for dependency
            unresolved = CIDS; % unresolved coordinate systems
            iter = 1;
            while ~all(unresolved==0) % keep trying until dependencies resolved
                for i = 2:ncord+1
                    if unresolved(i) ~= 0
                        r = find(CIDS==obj(i).RID);
                        if isempty(r)==1
                            error('Coordinate systems CID = %d references an undefined coodinate system CID = %d',obj(i).CID,obj(i).RID)
                        else
                            if unresolved(r) == 0
                                obj(i)=obj(i).prep(obj(r));
                                unresolved(i) = 0;
                            end
                        end
                    end
                end
                iter = iter + 1;
                if iter > ncord+2
                    error('There are dependency issues with coordinate system(s) CID = %s',sprintf('%d, ',unresolved(unresolved~=0)'))
                end
            end
            
        end
    end
end
