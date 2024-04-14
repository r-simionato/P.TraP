% MATLAB R2023b - imkeepborder
% Retain light structures connected to image border
% Copyright 2023 The MathWorks, Inc.

function out = imkeepborder(in,options)
    arguments
        in {mustBeNumericOrLogical, mustBeReal, mustBeNonsparse}
        options.Borders {mustBeBorders} = true(ndims(in),2)
        options.Connectivity {mustBeConnectivity} = ...
            ones(repmat(3,1,ndims(in)))
    end

    % Convert input connectivity to its canonical, multidimensional array
    % representation.
    conn = images.internal.getBinaryConnectivityMatrix(options.Connectivity);

    % Convert borders specification to its canonical matrix representation.
    B = borderMatrix(options.Borders);
    M_B = size(B,1);

    ndims_conn = ndims(conn);

    ndims_in = ndims(in);

    % Determine the working dimensionality.
    P = max([ndims_in ndims_conn M_B]);

    if M_B < P
        % Pad borders matrix with zeros to working dimensionality.
        B = [B ; zeros(P - M_B, 2)];
    end

    if P > ndims_conn
        % The working dimensionality is higher than the dimensionality of
        % the connectivity array. Extend the connectivity to the working
        % dimensionality.
        %
        % When a connectivity array is extended to the next higher
        % dimension, do it so that there is no connectivity in that new
        % dimension. This is achieved by "sandwiching" the connectivity
        % array, along the new dimension, between two same-shape arrays of
        % zeros. Repeat this process for as many dimensions as needed.
        for k = (ndims_conn+1):P
            extra_zeros = conn;
            extra_zeros(:) = 0;
            conn = cat(k,extra_zeros,conn,extra_zeros);
        end
    end

    % Get the input image size according to the working dimensionality.
    size_in = size(in,1:P);

    % General algorithm:
    %
    % Call the input image the mask image.
    %
    % Create a marker image array that is equal to the input array only
    % along the specified borders. At every other location, the marker
    % image is false or -Inf, depending on whether the input array is
    % logical.
    %
    % Then, perform morphological reconstruction using the mask and marker
    % images.
    %
    % Reference: Pierre Soille, Morphological Image Analysis: Principles
    % and Applications, Springer, 1999, pp. 164-165.
    
    % First, create a cell array of subscripts corresponding to where the
    % marker image will be false or -Inf. The set of borders to use is
    % specified by the matrix B. If B(k,1) is true, then we are using the
    % starting border along the k-th dimension. If B(k,2) is true, then we
    % are using the ending border along the k-th dimension.
    subs = cell(1,P);

    for dim = 1:P
        [use_first_border,use_second_border] = useBordersAlongDimension(dim,B,conn);
        if use_first_border
            first = 2;
        else
            first = 1;
        end

        if use_second_border
            last = size_in(dim)-1;
        else
            last = size_in(dim);
        end

        subs{dim} = first:last;
    end

    % Determine the value to use on the interior of the marker image array.
    if islogical(in)
        marker_min_value = false;
    else
        marker_min_value = -Inf;
    end

    % Initialize the marker image to be the same as the input array, and
    % then use the subscripts cell array to set all the interior elements
    % to marker_min_value.
    marker = in;
    marker(subs{:}) = marker_min_value;

    out = imreconstruct(marker,in,conn);
end

%borderMatrix Convert Borders input argument to canonical matrix form.
function B = borderMatrix(borders)
    if iscell(borders)
        % If the input is a cell array, it has already been validated by
        % mustBeBorders to be a vector and to have elements that are
        % members of {'left' 'right' 'top' 'bottom'}.

        % Convert the cellstr form to a string array for further processing
        % below.
        borders = string(borders);
    end

    if isstring(borders)
        % If the input is a string, it is a vector of one or more strings
        % containing 2-D border labels. Validity of the strings is not
        % checked here.
        B = false(2,2);
        for k = 1:length(borders)
            switch borders(k)
                case "top"
                    B(1,1) = true;
                case "bottom"
                    B(1,2) = true;
                case "left"
                    B(2,1) = true;
                case "right"
                    B(2,2) = true;
            end
        end
    else
        % If the input is not a string, then it is a two-column matrix.
        % Validity of of the matrix is not checked here.
        B = borders;
    end
end

% useBordersAlongDimension(dim,B,conn) determines whether to use the first
% and second border along a given dimension, based on the Borders matrix
% and the specified connectivity. Using a particular border depends on two
% factors: 
% 
% - whether the Borders matrix, B, indicates it. B(dim,1) indicates the
% first border along the specified dimension, and B(dim,2) indicates the
% second.
%
% - whether the connectivity indicates that pixels along that border are
% connected to the outside of the image. For example, if dim is 2, then if
% any of the values conn(:,1,:) is nonzero, then pixels on the left border
% of the input array are connected to the outside of the image. Similarly,
% if any of the values conn(:,3,:) is nonzero, then pixels on the right
% border of the input array are connected to the outside of the image.
function [use_first_border,use_second_border] = useBordersAlongDimension(dim,B,conn)
    P = size(B,1);
    conn_subs = repmat({1:3},1,P);
    
    if ~B(dim,1)
        use_first_border = false;
    else
        conn_subs{dim} = 1;
        use_first_border = any(conn(conn_subs{:}),"all");
    end

    if ~B(dim,2)
        use_second_border = false;
    else
        conn_subs{dim} = 3;
        use_second_border = any(conn(conn_subs{:}),"all");
    end
end

% Copyright 2023 The MathWorks, Inc.

function mustBeBorders(borders)

    if isstring(borders)
        mustBeVector(borders);
        mustBeMember(borders,["left" "right" "top" "bottom"]);
    elseif iscell(borders)
        mustBeVector(borders);
        mustBeMember(borders,{'left' 'right' 'top' 'bottom'});
    else
        mustBeNumericOrLogical(borders);

        if ~ismatrix(borders) || (size(borders,2) ~= 2) || (size(borders,1) < 2)
            error(message("images:validate:badBordersForm"))
        end

        mustBeMember(borders,[0 1]);
    end
end

% Copyright 2023 The MathWorks, Inc.

function mustBeConnectivity(conn) %#codegen
arguments
    conn {mustBeNumericOrLogical}
end

if isscalar(conn)
    mustBeMember(conn, [1 4 6 8 18 26])
else
    % If not a scalar, conn must be 3x3x ... x3.
    coder.internal.errorIf(any(size(conn) ~= 3),...
        'images:validate:badConnectivitySize');
    mustBeMember(conn, [0 1]);

    % For a 3x3x ... x3 array, linear indexing with (end+1)/2 gives the
    % center element, which is required to be 1.

    coder.internal.errorIf(conn((end+1)/2) ~= 1,...
        'images:validate:badConnectivityCenter');

    coder.internal.errorIf(~isequal(conn(1:end), conn(end:-1:1)),...
        'images:validate:nonsymmetricConnectivity');
end
end

% Copyright 2023 The MathWorks, Inc.