
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity AXIS_PACKET_GENERATOR is
	generic (
		tDATA_WIDTH					: integer := 8;
		PACKET_TO_SEND      		: string  := "123456,1212"; -- in hex
		Specific_Number_Of_Packets  : boolean := true; 
		Number_Of_Packets_To_Send	: integer := 10
	);
	port (

		SEND_PACKET		: in std_logic;
		M_AXIS_ACLK		: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_tREADY	: in std_logic;
		M_AXIS_tDATA 	: out std_logic_vector(tDATA_WIDTH-1 downto 0); 
		M_AXIS_tVALID 	: out std_logic; 
		M_AXIS_tLAST	: out std_logic 

	);
end AXIS_PACKET_GENERATOR;


architecture arch_imp of AXIS_PACKET_GENERATOR is

-------------------------------------------------------------------------------------
------ This function converts strings to binary with std_logic_vector type ----------
------------------------------------------------------------------------------------- 
function cal_stream_beats_cnt(s: string) return integer is 
	constant ss: string(1 to s'length) := s; 
	variable answer: integer := 1; 
begin 
    for i in ss'range loop
		if(ss(i) = ',') then 
		  answer  := answer + 1;
		end if; 
    end loop; 
    return answer;
end function;
   
constant NUM_OF_STREAM_BEATS    : integer := cal_stream_beats_cnt(PACKET_TO_SEND);
type arrayType is array(1 to NUM_OF_STREAM_BEATS) of integer; 
type out_pair is record
    whole_packet    : std_logic_vector(1 to 4 * (PACKET_TO_SEND'length - (NUM_OF_STREAM_BEATS - 1)));
    number_of_beats : arrayType;
end record;

function to_slv(s: string) return out_pair is 
	constant ss: string(1 to s'length) := s; 
	variable answer: std_logic_vector(1 to 8 * (s'length - (NUM_OF_STREAM_BEATS - 1))); 
	variable f_answer: std_logic_vector(1 to 4 * (s'length - (NUM_OF_STREAM_BEATS - 1))); 
    variable p: integer; 
    variable c: integer; 
    variable d: integer; 
    variable f: integer; 
    variable f_o : out_pair; 
	variable nob_indx : integer := 1; 
	variable ii : integer := 0; 
	variable iii : integer := 0; 
begin 
    for i in ss'range loop
		ii := ii + 1; 
	    f := 4 * ii; 
		if(ss(i) = ',') then 
			f_o.number_of_beats(nob_indx) := (f - 4) / tDATA_WIDTH;
			ii    		:= 0;
			nob_indx	:= nob_indx + 1; 
		else
		    iii := iii + 1;  
            p := 8 * iii;
            d := 4 * iii;
			--- converting to ASCI integer value --- 
			c := character'pos(ss(i));
			answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
			--- translate it to hex --- 
			if(unsigned(answer(p - 7 to p-4)) = 3) then --- numbers
				f_answer(d-3 to d)	:= answer(p - 3 to p); --- only 4-bit lsb
			elsif(unsigned(answer(p - 7 to p-4)) = 4) then--- letters
				f_answer(d-3 to d)	:= std_logic_vector(unsigned(answer(p - 3 to p)) + 9); --- only 4-bit lsb + 9
			end if;
		end if; 
		if(i = s'length) then 
			f_o.number_of_beats(nob_indx) := f / tDATA_WIDTH;
		end if; 
    end loop; 
    f_o.whole_packet  := f_answer;
    return f_o;
end function;

constant msb_bit_cnt 			: integer := (PACKET_TO_SEND'length - (NUM_OF_STREAM_BEATS - 1)) * 4;
constant HEX_SPECIAL_PACKET 	: STD_LOGIC_VECTOR(msb_bit_cnt-1 downto 0) := to_slv(PACKET_TO_SEND).whole_packet; 
constant NUM_OF_STREAM_BEATS_ARR: arrayType := to_slv(PACKET_TO_SEND).number_of_beats; 
constant packet_word_cnt 		: integer := msb_bit_cnt/tDATA_WIDTH; 
constant Wcnt 					: integer := packet_word_cnt-1; 

signal index 					: integer := 0; 
signal index_int 			    : integer := 1; 
signal beat_cnt 				: integer := 1; 
signal Packet_cnt 				: integer := 0; 
signal S_AXIS_tLAST_INT 		: std_logic := '0'; 
signal SEND_PACKET_INT  		: std_logic := '0'; 
signal Valid_Beat  				: std_logic := '0'; 
signal M_AXIS_tVALID_Int 		: std_logic := '0'; 

type StateType is (IDLE, SEND);
signal FSM : StateType := IDLE;

begin
M_AXIS_tVALID		<= M_AXIS_tVALID_Int; 
M_AXIS_tLAST   		<= S_AXIS_tLAST_INT;
Valid_Beat			<= M_AXIS_tREADY and M_AXIS_tVALID_Int;
M_AXIS_tDATA		<= HEX_SPECIAL_PACKET(tDATA_WIDTH*(Wcnt-index+1)-1 downto tDATA_WIDTH*(Wcnt-index+1)-tDATA_WIDTH);
S_AXIS_tLAST_INT	<= '1' when index = Wcnt and Valid_Beat = '1' else '0'; 
M_AXIS_tVALID_Int	<= '1' when FSM = SEND and Packet_cnt < Number_Of_Packets_To_Send else '0'; 
Specific_Number_Of_Packets_con: if(Specific_Number_Of_Packets=true) generate
process(M_AXIS_ACLK)
begin
	if rising_edge(M_AXIS_ACLK) then 
		if ( M_AXIS_ARESETN = '0' ) then
			Packet_cnt			<= 0;
			index				<= 0;
			index_int		    <= 1;
			beat_cnt		    <= 1;
			FSM					<= IDLE;
		else 		
			SEND_PACKET_INT		<= SEND_PACKET;
			case FSM is 	
				when IDLE => 
					if(SEND_PACKET = '1' and SEND_PACKET_INT = '0') then 
						FSM		    <= SEND;
						index_int	<= 1; 
					end if; 
				when SEND => 
					if(Valid_Beat = '1') then 	
						index				<= index + 1; 
						index_int           <= index_int + 1; 
						if(index_int = NUM_OF_STREAM_BEATS_ARR(beat_cnt) and NUM_OF_STREAM_BEATS > 1) then 
                            beat_cnt    <= beat_cnt + 1; 
                            index_int   <= 1;
                            FSM         <= IDLE;
						end if; 
						if(index = wcnt)then 
						    beat_cnt			<= 1; 
						    index				<= 0;
							if(NUM_OF_STREAM_BEATS = 1) then 
						    	Packet_cnt			<= Packet_cnt +1;
							end if; 
						end if; 
					end if; 
					if(Packet_cnt = Number_Of_Packets_To_Send and NUM_OF_STREAM_BEATS = 1) then 
						Packet_cnt	  		<= 0;
						FSM			   		<= IDLE;
					end if; 	
				when others => 
			end case ;
		end if; 
	end if;
end process;
end generate Specific_Number_Of_Packets_con;


nSpecific_Number_Of_Packets_con: if(Specific_Number_Of_Packets=false) generate
	process(M_AXIS_ACLK)
	begin
		if rising_edge(M_AXIS_ACLK) then 
			if ( M_AXIS_ARESETN = '0' ) then
				index				<= 0;
				FSM					<= IDLE;
			else 		
				SEND_PACKET_INT		<= SEND_PACKET;	
				case FSM is 
					when IDLE => 
						if(SEND_PACKET='1') then 
							FSM	<= SEND;
						end if; 
					when SEND => 
						if(Valid_Beat = '1') then 
							index				<= index +1; 
							if(index = Wcnt)then 
								index				<= 0;
								FSM					<= IDLE;
							end if; 
						end if; 
					when others => 
				end case ;
			end if; 
		end if;
	end process;
end generate nSpecific_Number_Of_Packets_con;
end arch_imp;
