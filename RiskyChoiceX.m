classdef RiskyChoiceX < ProtoObj
    
    %This RiskyChoiceX protocol trains the rat to associate BLED with the
    %surebet port and YLED with the lottery port; also to learn the mapping
    %from 1k,2k,4k,8k,16kHz sounds to 0,64,128,256,512ul water lottery reward
    %with 50% probability and to choose accordingly.
    
    % Port locations are side-independent, yet equal in effort required
    % Written by Xiaoyue Zhu, March 2018
    
    properties
        
        ITI
        protocol_data
        Sounds
        start_port
        reward_port
        lottery_port
        surebet_port
        trial_in_block = 0
        block_num = 0
        trial_num = 0
        forced_surebet
        forced_lottery
        forced_trial
        lottery_value
        surebet_value
        lottery_prob
        lottery_outcome
        lottery_value_in_block
        lottery_prob_in_block
        ft %fixation time for each trial
        init_time %time elapsed between start_port LED on and the first poke
        resp_time% time elapsed between choice_port LED on and the choice poke
        fixation_attempts
        one_fixation
        n_wrong_pokes
        init_timeout
        choice_timeout
        timeout
        good_trial
        rational_choice % assuming the animal is risk-neutral
        
    end
    
    methods
        
        function [x, y] = init(obj, varargin)
            [x,y] = init@ProtoObj(obj, varargin);
            SF = PsychSound.SF;
            
            obj.Sounds.StartSound = PsychSound(GenerateSineWave(SF, 500, .1));
            obj.Sounds.GoSound = PsychSound([GenerateSineWave(SF, 8, .1) .* GenerateSineWave(SF, 2000, .1) 0*GenerateSineWave(SF, 2000, .1)]);
            obj.Sounds.LotterySound = PsychSound(GenerateSineWave(SF, 1000, .5)); %This is just a place holder
            obj.Sounds.SurebetSound = PsychSound(GenerateSineWave(SF, 1000, .5)); %1k sound for surebet
            obj.Sounds.ShortViolSound = PsychSound(rand(1,SF*.1)*2 - 1);
            
            obj.Sounds.ShortViolSound.volume = 0.3;
            obj.Sounds.StartSound.volume = 0.5;
            obj.Sounds.GoSound.volume = 0.5;
            obj.Sounds.LotterySound.volume = 0.5;
            obj.Sounds.SurebetSound.volume = 0.5;
        end
        
        function useSettings(obj, settings_name, expg_data, subj_data)
            
            if isempty(settings_name)
                settings_name = 'free_simple';
            end
            
            switch settings_name
                
                case 'forced_blocks_simple'
                    % forced, blocks, only two possible port locations
                    obj.settings.name = 'forced_blocks_simple';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 5;
                    obj.settings.ITI_max = 15;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 0.1;
                    
                    obj.settings.block_length = 10;
                    obj.settings.forced_surebet_length = 5;
                    obj.settings.surebet_value = 16; %given 30% surebet and 20ml intake
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16]; % Each for 1k, 2k, 4k, 8k and 16k sounds
                    obj.settings.lottery_value_probs = [4,0,0,0,6]; % Default
                    obj.settings.lottery_payout_probs = [0.5]; %Just 0.5 for now
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR'}; %Here we only start with two possible locaitons
                    obj.settings.side_correction = nan;
                    
                case 'forced_blocks_medium'
                    % forced, blocks, 4 port locations
                    obj.settings.name = 'forced_blocks_medium';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 5;
                    obj.settings.ITI_max = 15;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    
                    obj.settings.block_length = 10;
                    obj.settings.forced_surebet_length = 3;
                    obj.settings.surebet_value = 16;
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16];
                    obj.settings.lottery_value_probs = [4,0,0,0,6]; % Default
                    obj.settings.lottery_payout_probs = [0.5];
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR','MidL','MidR'};
                    obj.settings.side_correction = nan;
                    
                case 'forced_blocks_full'
                    % forced, blocks, 6 full possible port locations
                    obj.settings.name = 'forced_blocks_full';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 5;
                    obj.settings.ITI_max = 15;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    
                    obj.settings.block_length = 10;
                    obj.settings.forced_surebet_length = 3;
                    obj.settings.surebet_value = 16;
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16];
                    obj.settings.lottery_value_probs = [4,0,0,0,6]; % Default
                    obj.settings.lottery_payout_probs = [0.5];
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR','MidL','MidR','TopL','TopR'};
                    obj.settings.side_correction = nan;
                    
                case 'free_simple'
                    obj.settings.name = 'free_simple';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 10;
                    obj.settings.ITI_max = 30;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1 ;
                    
                    obj.settings.surebet_value = 8; %base reward
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16];
                    obj.settings.lottery_value_probs = [4 0 0 0 6]; %we change this depending on animal's performance
                    obj.settings.lottery_payout_probs = [0.5]; %Just 0.5 for now
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR'};
                    obj.settings.side_correction = nan;
                    
                case 'mixed_simple'
                    obj.settings.name = 'mixed_simple';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 5;
                    obj.settings.ITI_max = 15;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    
                    obj.settings.block_length = 30;
                    obj.settings.n_forced = 10; % 10 forced trials, 10 free trials in a block
                    obj.settings.n_forced_surebet = 5;
                    obj.settings.surebet_value = 16;
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16];
                    obj.settings.lottery_value_probs = [4,0,0,0,6]; % Default
                    obj.settings.lottery_payout_probs = [0.5];
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR'};
                    obj.settings.side_correction = nan;
                    
                case 'mixed_simple_fix'
                    % it only differs from mixed_simple that the animal
                    % is still learning to fixate, yet it can fixate for
                    % at least 500ms
                    obj.settings.name = 'mixed_simple_fix';
                    obj.settings.led_brightness_on = 0.5;
                    obj.settings.led_brightness_off = 0;
                    obj.settings.ITI_min = 5;
                    obj.settings.ITI_max = 15;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 0.5;
                    
                    obj.settings.block_length = 30;
                    obj.settings.n_forced = 10; % 10 forced trials, 10 free trials in a block
                    obj.settings.n_forced_surebet = 5; % 3 forced surebet, 7 forced lottery
                    obj.settings.surebet_value = 16;
                    acs = obj.settings.surebet_value;
                    obj.settings.lottery_values = [acs*1,acs*2,acs*4,acs*8,acs*16];
                    obj.settings.lottery_value_probs = [4,0,0,0,6]; % Default
                    obj.settings.lottery_payout_probs = [0.5];
                    obj.settings.lottery_payout_prob_probs = [1];
                    
                    obj.settings.poke_config_list = {'BotL','BotR'};
                    obj.settings.side_correction = nan;
                    
                otherwise
                    obj.settings = [];
            end
            obj.settings = utils.apply_struct(obj.settings, subj_data);
            
        end
        
        
        function prepareNextTrial(obj)
            
            %First trial ITI = 1s
            if obj.n_done_trials == 0
                obj.ITI = 1;
            else
                obj.ITI = rand*(obj.settings.ITI_max-obj.settings.ITI_min)+obj.settings.ITI_min;
            end
            
            if strcmpi(obj.settings.name, 'forced_blocks_simple') || strcmpi(obj.settings.name, 'mixed_simple_fix')
                if obj.n_done_trials == 0
                    obj.ft = obj.settings.ft_init;
                else
                    %If the last trial is a one-fixation trial, we increase ft in this trial
                    %by 5ms; if not, we decrease ft by 5ms
                    obj.ft = utils.adaptive_step(obj.ft, obj.one_fixation(end),...
                        'hit_step',0.005,'stableperf',0.5,'mx',1,'mn',obj.settings.ft_init);
                end
            else obj.ft = obj.settings.ft_init;
            end
            
            
            obj.trial_num = obj.trial_num + 1;
            obj.trial_in_block = obj.trial_in_block +1 ;
            
            obj.start_port = 'MidC';
            obj.reward_port = 'BotC';
            
            % Initialize the next block only for forced_blocks
            if strncmpi(obj.settings.name, 'forced_blocks',13)
                
                if obj.trial_in_block > obj.settings.block_length || obj.trial_num == 1
                    obj.trial_in_block = 1;
                    obj.block_num = obj.block_num + 1;
                    % In forced_blocks, we pick a lottery value and use it throughout this block
                    obj.lottery_value = utils.pick_with_prob(obj.settings.lottery_values, obj.settings.lottery_value_probs);
                    obj.lottery_value_in_block = obj.lottery_value;
                    obj.lottery_prob = utils.pick_with_prob(obj.settings.lottery_payout_probs, obj.settings.lottery_payout_prob_probs);
                    obj.lottery_prob_in_block = obj.lottery_prob;
                    obj.surebet_value = obj.settings.surebet_value;
                else obj.lottery_value = obj.lottery_value_in_block;
                    obj.lottery_prob = obj.lottery_prob_in_block;
                    obj.surebet_value = obj.settings.surebet_value;
                end
                obj.forced_trial = 1;
                
                %The first 3 trials in a block is forced surebet
                obj.forced_surebet = obj.trial_in_block <= obj.settings.forced_surebet_length;
                
            elseif strcmpi(obj.settings.name, 'free_simple')
                obj.surebet_value = obj.settings.surebet_value;
                obj.lottery_value = utils.pick_with_prob(obj.settings.lottery_values, obj.settings.lottery_value_probs);
                obj.lottery_prob = utils.pick_with_prob(obj.settings.lottery_payout_probs, obj.settings.lottery_payout_prob_probs);
                obj.forced_trial = 0;
                obj.forced_surebet = 0;
                
                
            elseif strncmpi(obj.settings.name, 'mixed',5)
                
                if obj.trial_in_block > obj.settings.block_length || obj.trial_num == 1
                    obj.trial_in_block = 1;
                    obj.block_num = obj.block_num + 1;
                    obj.lottery_value = utils.pick_with_prob(obj.settings.lottery_values, obj.settings.lottery_value_probs);
                    obj.lottery_prob = utils.pick_with_prob(obj.settings.lottery_payout_probs, obj.settings.lottery_payout_prob_probs);
                    obj.surebet_value = obj.settings.surebet_value;
                    obj.lottery_value_in_block = obj.lottery_value;
                    obj.lottery_prob_in_block = obj.lottery_prob;
                    obj.forced_trial = 1;
                    %Keep lottery value constant in a block
                else obj.lottery_value = obj.lottery_value_in_block;
                    obj.lottery_prob = obj.lottery_prob_in_block;
                    obj.surebet_value = obj.settings.surebet_value;
                end
                obj.forced_trial = obj.trial_in_block <= obj.settings.n_forced;
                obj.forced_surebet = obj.trial_in_block <= obj.settings.n_forced_surebet;
                obj.forced_lottery = obj.trial_in_block <= obj.settings.n_forced & ...
                    obj.trial_in_block > obj.settings.n_forced_surebet;
            end
            
            % Allocate lottery/sb ports depending on settings name and
            % side_correction
            norm_delta = (obj.lottery_value*obj.lottery_prob - obj.surebet_value) / (obj.surebet_value*16*obj.lottery_prob - obj.surebet_value);
            [obj.lottery_port, obj.surebet_port] = allocate_port(obj.settings.name, obj.settings.poke_config_list, obj.settings.side_correction, norm_delta);
            
            
            %Set up lottery sound
            SF = PsychSound.SF;
            obj.Sounds.LotterySound.wave = GenerateSineWave(SF, (obj.lottery_value/obj.surebet_value)*1000, .5);
            % JCE: changed this.
            
            %Set up lottery outcome
            obj.lottery_outcome = rand<=obj.lottery_prob;
            % 1k sound never pays
            if obj.lottery_value == obj.settings.surebet_value
                obj.lottery_outcome = 0;
            end
            
            fprintf(1,'Settings: %s \n Trial: %d \t ITI: %.1f\n',obj.settings.name,obj.trial_num, obj.ITI);
            fprintf(1,'Block %d \t Lottery value: %0.0f nl \t Lottery outcome: %d \n', obj.block_num, obj.lottery_value, obj.lottery_outcome);
        end
        
        function sma = generateSM(obj)
            
            %% Setup some variable. These normally could go into prepareNextTrial()
            sett = obj.settings;
            snd = obj.Sounds;
            sma = NewStateMatrix(); % Assemble state matrix
            surebet_valve_time = GetValveTimes(obj.surebet_value, 1);
            lottery_valve_time = GetValveTimes(obj.lottery_value, 1);
            
            % Trial starts, LED on in the start port
            sma = AddState(sma, 'name','trial_start','Timer',0.001,...
                'StateChangeConditions',{'Tup','wait_for_poke'});
            
            
            if strncmpi(obj.settings.name, 'forced_blocks',13)
                if obj.forced_surebet
                    fixation_state = 'surebet_fixation';
                    fixation_complete_state = 'fixation_complete_forced_sb';
                    back_from_viol = 'surebet_lit';
                else
                    fixation_state = 'fixation_and_sound';
                    fixation_complete_state = 'fixation_complete_forced_lott';
                    back_from_viol = 'lottery_lit';
                end
            elseif strcmpi(obj.settings.name, 'free_simple')
                fixation_state = 'fixation_and_sound';
                fixation_complete_state = 'fixation_complete_free';
                back_from_viol = 'both_lit';
            elseif strncmpi(obj.settings.name, 'mixed',5)
                if obj.forced_surebet
                    fixation_state = 'surebet_fixation';
                    fixation_complete_state = 'fixation_complete_forced_sb';
                    back_from_viol = 'surebet_lit';
                elseif obj.forced_lottery
                    fixation_state = 'fixation_and_sound';
                    fixation_complete_state = 'fixation_complete_forced_lott';
                    back_from_viol = 'lottery_lit';
                else
                    fixation_state = 'fixation_and_sound';
                    fixation_complete_state = 'fixation_complete_free';
                    back_from_viol = 'both_lit';
                end
            end
            
            %We introduce blinking side ports to facilitate learning
            if strcmpi(obj.settings.name, 'forced_blocks_simple')
                blinking = 1;
            else blinking = 0;
            end
            
            
            
            sma = AddState(sma, 'name','wait_for_poke','Timer',obj.settings.start_timeout,...
                'StateChangeConditions',{'Tup','viol_timeout_init',pokeIn(obj.start_port),fixation_state,'OtherIn','viol_sound_init'},...
                'OutputActions',{'PlaySound',snd.StartSound.id, blueLight(obj.start_port),1, yellowLight(obj.start_port),1});
            
            %Lottery fixation state
            sma = AddState(sma, 'name','fixation_and_sound','Timer',obj.ft,...
                'StateChangeConditions',{'Tup',fixation_complete_state,pokeOut(obj.start_port),'trial_start'},...
                'OutputActions',{blueLight(obj.start_port),0, yellowLight(obj.start_port),0,...
                'PlaySound',snd.LotterySound.id});
            
            %Surebet fixation state
            sma = AddState(sma, 'name','surebet_fixation','Timer',obj.ft,...
                'StateChangeConditions',{'Tup', fixation_complete_state, pokeOut(obj.start_port),'trial_start'},...
                'OutputActions',{blueLight(obj.start_port),0, yellowLight(obj.start_port),0,...
                'PlaySound',snd.SurebetSound.id});
            
            % If it's a forced surebet trial: only surebet port lit
            sma = AddState(sma, 'name','fixation_complete_forced_sb','Timer',0.001,...
                'StateChangeConditions',{'Tup','surebet_lit'},...
                'OutputActions', {'PlaySound',snd.GoSound.id});
            
            % If it's a forced lottery trial: only lottery port lit
            sma = AddState(sma, 'name','fixation_complete_forced_lott','Timer',0.001,...
                'StateChangeConditions',{'Tup','lottery_lit'},...
                'OutputActions', {'PlaySound',snd.GoSound.id});
            
            % If it's a free choice trial: both ports lit
            sma = AddState(sma, 'name','fixation_complete_free','Timer',0.001,...
                'StateChangeConditions',{'Tup','both_lit'},...
                'OutputActions', {'PlaySound',snd.GoSound.id});
            
            if obj.lottery_outcome
                chose_lottery_state = 'chose_lottery_win';
            else chose_lottery_state = 'chose_lottery_lose';
            end
            
            
            if blinking
                %Set a gloabl timer for choice timeout while it blinks
                choice_timer_index = 1;
                sma = SetGlobalTimer(sma, choice_timer_index, obj.settings.choice_timeout);
                choice_timer_end = sprintf('GlobalTimer%d_End', choice_timer_index);
                
                
                sma = AddState(sma, 'name','surebet_lit','Timer',0.01,...
                    'StateChangeConditions',{'Tup','surebet_blink1'},...
                    'OutputActions', {'GlobalTimerTrig',choice_timer_index});
                
                sma = AddState(sma, 'name','surebet_blink1','Timer',0.1,...
                    'StateChangeConditions',{'Tup','surebet_blink2',pokeIn(obj.surebet_port),'chose_surebet','OtherIn','viol_sound_choice',...
                    choice_timer_end,'viol_timeout_choice'},...
                    'OutputActions', {blueLight(obj.surebet_port),1});
                
                sma = AddState(sma, 'name','surebet_blink2','Timer',0.1,...
                    'StateChangeConditions',{'Tup','surebet_blink1',pokeIn(obj.surebet_port),'chose_surebet','OtherIn','viol_sound_choice',...
                    choice_timer_end,'viol_timeout_choice'},...
                    'OutputActions', {blueLight(obj.surebet_port),0});
                
                
                sma = AddState(sma, 'name','lottery_lit','Timer',0.01,...
                    'StateChangeConditions',{'Tup','lottery_blink1'},...
                    'OutputActions', {'GlobalTimerTrig',choice_timer_index});
                
                sma = AddState(sma, 'name','lottery_blink1','Timer',0.1,...
                    'StateChangeConditions',{'Tup','lottery_blink1',pokeIn(obj.lottery_port),chose_lottery_state,'OtherIn','viol_sound_choice',...
                    choice_timer_end,'viol_timeout_choice'},...
                    'OutputActions', {yellowLight(obj.lottery_port),1});
                
                sma = AddState(sma, 'name','lottery_blink2','Timer',0.1,...
                    'StateChangeConditions',{'Tup','lottery_blink2',pokeIn(obj.lottery_port),chose_lottery_state,'OtherIn','viol_sound_choice',...
                    choice_timer_end,'viol_timeout_choice'},...
                    'OutputActions', {yellowLight(obj.lottery_port),0});
                
                
            elseif ~blinking
                
                sma = AddState(sma, 'name','surebet_lit','Timer',obj.settings.choice_timeout,...
                    'StateChangeConditions',{'Tup','viol_timeout_choice',pokeIn(obj.surebet_port),'chose_surebet','OtherIn','viol_sound_choice'},...
                    'OutputActions', {blueLight(obj.surebet_port),1});
                
                sma = AddState(sma, 'name','lottery_lit','Timer',obj.settings.choice_timeout,...
                    'StateChangeConditions',{'Tup','viol_timeout_choice',pokeIn(obj.lottery_port),chose_lottery_state,'OtherIn','viol_sound_choice'},...
                    'OutputActions', {yellowLight(obj.lottery_port),1});
                
            end
            
            
            
            sma = AddState(sma, 'name','both_lit','Timer',obj.settings.choice_timeout,...
                'StateChangeConditions',{'Tup','viol_timeout_choice',pokeIn(obj.surebet_port),'chose_surebet',...
                pokeIn(obj.lottery_port),chose_lottery_state,'OtherIn','viol_sound_choice'},...
                'OutputActions', {blueLight(obj.surebet_port),1,yellowLight(obj.lottery_port),1});
            
            
            % If chose surebet: surebet port LED off, reward port LED on
            sma = AddState(sma, 'name', 'chose_surebet', ...
                'StateChangeConditions', {pokeIn(obj.reward_port),'get_surebet_reward'},...
                'OutputActions',{blueLight(obj.surebet_port),0,yellowLight(obj.lottery_port),0,...
                'BotCled', sett.led_brightness_on});
            
            % If lottery wins: lottery port LED off, reward port LED on
            sma = AddState(sma, 'name', 'chose_lottery_win', ...
                'StateChangeConditions', {pokeIn(obj.reward_port),'get_lottery_reward'},...
                'OutputActions',{yellowLight(obj.lottery_port),0,blueLight(obj.surebet_port),0,...
                'BotCled', sett.led_brightness_on});
            
            % If lottery loses: it goes to the next trial
            sma = AddState(sma, 'name', 'chose_lottery_lose', 'Timer',0.001,...
                'StateChangeConditions', {'Tup','ITI'},...
                'OutputActions',{yellowLight(obj.lottery_port),0,blueLight(obj.surebet_port),0});
            
            % animal gets the surebet reward
            sma = AddState(sma, 'name', 'get_surebet_reward', 'Timer', surebet_valve_time,...
                'StateChangeConditions', {'Tup','ITI'},...
                'OutputActions',{'ValveState',1,'BotCled', sett.led_brightness_off});
            
            % animal gets the lottery reward
            sma = AddState(sma, 'name', 'get_lottery_reward', 'Timer', lottery_valve_time,...
                'StateChangeConditions', {'Tup','ITI'},...
                'OutputActions',{'ValveState',1,'BotCled', sett.led_brightness_off});
            
            % a new ITI begins
            sma = AddState(sma, 'name','ITI','Timer', obj.ITI, ...
                'StateChangeConditions', {'Tup','exit'});
            
            %Timeout
            sma = AddState(sma, 'Name','viol_timeout_init','Timer',0.001,...
                'StateChangeConditions',{'Tup','ITI'});
            
            sma = AddState(sma, 'Name','viol_timeout_choice','Timer',0.001,...
                'StateChangeConditions',{'Tup','ITI'});
            
            %Violation sound
            sma = AddState(sma, 'Name','viol_sound_init','Timer',0.1,...
                'OutputActions',{'PlaySound',snd.ShortViolSound.id},...
                'StateChangeConditions',{'Tup','wait_for_poke'});
            
            sma = AddState(sma, 'Name','viol_sound_choice','Timer',0.1,...
                'OutputActions',{'PlaySound',snd.ShortViolSound.id},...
                'StateChangeConditions',{'Tup',back_from_viol});
            
            
            obj.statematrix = sma;
            
        end
        
        function trialCompleted(obj)
            
            parsed_events = obj.peh(end);
            
            % Find the animal's choice
            all_states = fields(parsed_events.States);
            entered_states_index = structfun(@(x)~isnan(x(1)), parsed_events.States);
            entered_states = all_states(entered_states_index);
            choice_state = findState('chose_', entered_states);
            choice_split = strsplit(choice_state, '_');
            obj.choice = choice_split{2};
            if strcmpi(obj.choice, 'lottery')
                obj.choice = 1;
                obj.reward = obj.lottery_value * obj.lottery_outcome;
                
            elseif strcmpi(obj.choice, 'surebet')
                obj.choice = 0;
                obj.reward = obj.surebet_value;
            else obj.choice = nan;
                disp('Animal did not choose within choice_timeout.');
            end
            
            obj.hit = 0;
            obj.viol = sum(strncmpi(entered_states, 'viol_timeout',12));
            obj.init_timeout = sum(strcmpi(entered_states, 'viol_timeout_init'));
            obj.choice_timeout = sum(strcmpi(entered_states, 'viol_timeout_choice'));
            obj.good_trial = 0;
            obj.timeout = 0;
            
            % Get init_time and resp_time
            if obj.init_timeout
                obj.init_time = nan;
            elseif ~obj.init_timeout
                obj.init_time = parsed_events.States.wait_for_poke(1,2) - parsed_events.States.trial_start(1,2);
            end
            
            if isnan(obj.choice)
                obj.resp_time = nan;
            end
            
            if obj.choice_timeout
                obj.resp_time = nan;
            elseif ~obj.choice_timeout
                if obj.forced_surebet
                    obj.resp_time = parsed_events.States.surebet_lit(1,2) - parsed_events.States.surebet_lit(1,1);
                elseif obj.forced_lottery
                    obj.resp_time = parsed_events.States.lottery_lit(1,2) - parsed_events.States.lottery_lit(1,1);
                elseif ~obj.forced_trial % if free trial
                    obj.resp_time = parsed_events.States.both_lit(1,2) - parsed_events.States.both_lit(1,1);
                end
            end
            
            % Hit and Viol
            if obj.init_timeout == 1 || obj.choice_timeout == 1
                obj.reward = 0;
                obj.timeout = 1;
            end
            
            
            % Get fixation related information
            obj.fixation_attempts = size(parsed_events.States.trial_start,1)-1;
            
            [all_poke_times, all_poke_types]= getAllPokes(parsed_events);
            obj.n_wrong_pokes = length(all_poke_types) - obj.fixation_attempts - 2;
            if obj.n_wrong_pokes < 0
                obj.n_wrong_pokes = 0;
            end
            
            if strcmpi(obj.settings.name, 'forced_blocks_simple') || strcmpi(obj.settings.name, 'mixed_simple_fix')
                if obj.fixation_attempts == 0 && obj.timeout ~= 1
                    obj.one_fixation = 1; % fix the time_out decrease ft problem
                elseif obj.timeout == 1
                    obj.one_fixation = rand < 0.5; % bc adaptive step function won't take 0.5
                else obj.one_fixation = 0;
                end
                
            end
            
            
            % A good trial is defined by
            if obj.fixation_attempts < 1 && obj.init_time <10 && obj.resp_time <5
                obj.good_trial = 1;
            end
            
            % A hit is defined by
            if strncmpi(obj.settings.name,'forced_blocks',13)
                if obj.good_trial
                    obj.hit = 1;
                end
                obj.rational_choice = nan;
                
            elseif strncmpi(obj.settings.name,'mixed',5)
                if obj.forced_trial
                    if obj.good_trial
                        obj.hit = 1;
                    end
                    obj.rational_choice = nan;
                else %in free choice, a risk-neutral animal should choose lottery when delta-EV is positive
                    if obj.choice == (obj.lottery_value * obj.lottery_prob > obj.surebet_value)
                        if obj.good_trial
                            obj.hit = 1;
                        end
                        obj.rational_choice = 1;
                    else obj.rational_choice = 0;
                    end
                end
                
            elseif strncmpi(obj.settings.name,'free',4)
                if obj.choice == (obj.lottery_value * obj.lottery_prob >= obj.surebet_value)
                    if obj.good_trial
                        obj.hit = 1;
                    end
                    obj.rational_choice = 1;
                else obj.rational_choice = 0;
                end
            end
            
            
            % Other stuff we apparently need to save
            ndt = obj.n_done_trials;
            obj.choice_history{ndt} = obj.choice;
            obj.violation_history(ndt) = obj.viol;
            obj.reward_history(ndt) = obj.reward;
            obj.hit_history(ndt) = obj.hit;
            obj.RT_history(ndt) = obj.resp_time;
        end
        
        
        function savedata = getProtoTrialData(obj)
            % This should be a struct that matches a protocol specific table.
            savedata = obj.protocol_data;
            savedata.ITI = obj.ITI;
            savedata.fixation_time = obj.ft;
            savedata.fixation_attempts = obj.fixation_attempts;
            savedata.one_fixation = obj.one_fixation;
            savedata.init_time = obj.init_time;
            savedata.resp_time = obj.resp_time;
            savedata.n_wrong_pokes = obj.n_wrong_pokes;
            
            savedata.lottery_value = obj.lottery_value;
            savedata.lottery_prob = obj.lottery_prob;
            savedata.lottery_outcome = obj.lottery_outcome;
            savedata.lottery_port = obj.lottery_port;
            savedata.surebet_port = obj.surebet_port;
            
            savedata.choice = obj.choice;
            savedata.reward = obj.reward;
            savedata.forced_trial = obj.forced_trial;
            savedata.init_timeout = obj.init_timeout;
            savedata.choice_timeout = obj.choice_timeout;
            savedata.rational_choice = obj.rational_choice;
            savedata.good_trial = obj.good_trial;
            
        end
        
        
        function list = trialPropertiesToSave(obj)
            parentlist = trialPropertiesToSave@ProtoObj(obj);
            
            list = [ parentlist;
                { 'ITI' };
                { 'init_time',
                'resp_time',
                'lottery_value',
                'lottery_outcome',
                'fixation_attempts',
                'ft',
                'lottery_port',
                'surebet_port',
                'forced_surebet',
                'forced_trial',
                'block_num',
                'init_timeout',
                'choice_timeout',
                'good_trial',
                'rational_choice',
                'n_wrong_pokes'}];
        end
        
        function next_settings = prepareNextSession(obj)
            next_settings = [];
            if strcmpi(obj.settings.name,'forced_blocks_simple')
                next_settings.ft_init = obj.ft(end);
                next_settings.lottery_value_probs = upgrade_lvp(obj.settings.lottery_value_probs,nanmean(obj.hit_history),0.65);
                if nanmean(obj.hit_history)>0.99 %For now bumping is done manually
                    obj.saveload.stage = obj.saveload.stage + 1;
                end
                
            elseif strncmpi(obj.settings.name,'mixed',5)
                if nanmean(obj.hit_history)>0.99 %For now bumping is done manually
                    obj.saveload.stage = obj.saveload.stage + 1;
                end
                next_settings.ft_init = obj.ft(end);
                next_settings.lottery_value_probs = upgrade_lvp(obj.settings.lottery_value_probs,nanmean(obj.rational_choice),0.65);
                
                
            elseif strcmpi(obj.settings.name,'free_simple')
                next_settings.lottery_value_probs = upgrade_lvp(obj.settings.lottery_value_probs,nanmean(obj.rational_choice),0.65);
                
                %These animals have side bias
                if obj.saveload.subjid == 2048 || obj.saveload.subjid == 2049 
                    next_settings.side_correction = 1; % 2048, 2049 have big left bias
                end 
            end
        end
    end
end





function lvp = upgrade_lvp(current_lvp,criterion,threshold)
%Choose appropriate lottery value probs based on animal's free
%choice

A = [4 0 0 0 6]; % just 1k and 32k;
B = [3 2.5 0 2.5 2]; % 1k, 2k, 16K and 32k;
C = [1 1 1 1 1]; % all sounds
prob_matrix = [A;B;C];
lvp = current_lvp;
if criterion >= threshold
    for ii = 1:size(prob_matrix,1)-1
        if isequal(current_lvp,prob_matrix(ii,:))
            lvp = prob_matrix(ii+1,:);
        end
    end
end
end

function [lottery_port, surebet_port] = allocate_port(settings, poke_list, side_correction, norm_delta)
% Allocate port sides in different settings
% side_adapt allows for correcting port bias, 0.5 is default, 1 means left
% port being lottery all the time, 0 means left port being surebet always 
% norm_delta = normalised delta EV
if nargin < 3
    side_adapt = 0.5;
end

% default 
if isnan(side_correction)
    side_adapt = 0.5;
end

% If animal to be corrected to the right, we want side_adapt -> 1 when norm_delta <= 0, and side_adapt -> 0 when norm_delta > 0
% If animal to be corrected to the left, we want side_adapt -> 0 when norm_delta <= 0, and side_adapt -> 1 when norm_delta > 0
if side_correction == 1 % if the animal to be corrected to the right
    if norm_delta <= 0
        side_adapt = 0.7 + (1-0.7).*rand(1);
    elseif norm_delta > 0
        side_adapt = 0.2 * rand(1);
    end
elseif side_correction == 0 % if the animal to be corrected to the left
    if norm_delta <= 0
        side_adapt = 0.2 * rand(1);
    elseif norm_delta > 0
        side_adapt = 0.7 + (1-0.7).*rand(1);
    end
end


lott_inx = utils.pick_with_prob([1 2],[side_adapt, 1-side_adapt]);
if lott_inx == 1
    sb_inx = 2;
elseif lott_inx == 2;
    sb_inx = 1;
end



if strcmpi(settings,'forced_blocks_simple') || strncmpi(settings,'mixed',5) || strcmpi(settings,'free_simple')
    
    lottery_port = poke_list{lott_inx};
    surebet_port = poke_list{sb_inx};
    
elseif strcmpi(settings,'forced_blocks_medium')|| strcmpi(settings,'free_medium')
    
    level_inx = datasample([1,2],1);
    bot_list = {poke_list{1:2}};
    mid_list = {poke_list{3:4}};
    if level_inx == 1
        lottery_port = bot_list{lott_inx};
        surebet_port = bot_list{sb_inx};
    elseif level_inx == 2
        lottery_port = mid_list{lott_inx};
        surebet_port = mid_list{sb_inx};
    else disp('Something went wrong with port selection.');
    end
    
elseif strcmpi(settings,'forced_blocks_full') || strcmpi(settings,'free_full')
    level_inx = datasample([1,2,3],1);
    bot_list = {poke_list{1:2}};
    mid_list = {poke_list{3:4}};
    top_list = {poke_list{5:6}};
    if level_inx == 1
        lottery_port = bot_list{lott_inx};
        surebet_port = bot_list{sb_inx};
    elseif level_inx == 2
        lottery_port = mid_list{lott_inx};
        surebet_port = mid_list{sb_inx};
    elseif level_inx == 3
        lottery_port = top_list{lott_inx};
        surebet_port = top_list{sb_inx};
    else disp('Something went wrong with port selection.');
    end
end
end